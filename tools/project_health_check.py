#!/usr/bin/env python3
"""Run the project's repeatable health checks."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


RETIRED_PATHS = (
    "assets/placeholders/audio",
    "res://assets/placeholders/audio",
)
GODOT_IGNORED_HELPER_DIRS = (
    "tools/voice_generation",
    "tools/voice_comparison",
    "tmp",
    "_qa_previews",
    "_assets_archive",
)

GODOT_TIMEOUT_SECONDS = 60
GODOT_LOG_ERROR_MARKERS = (
    "SCRIPT ERROR:",
    "ERROR:",
    "CRASH:",
)
WINDOWS_ERROR_MODE_FLAGS = 0x0001 | 0x0002 | 0x8000
ANDROID_VOICE_PACK_TREE = "sounds/voice_over/locales/"
ANDROID_SHARED_VOICE_PATTERN = "sounds/voice_over/*.ogg"
ANDROID_BASE_SANTA_FALLBACK = "sounds/voice_over/locales/en-US/santa_full_greeting.ogg"


def run_step(label: str, command: list[str], cwd: Path, timeout: int | None = None) -> int:
    print(f"\n== {label} ==")
    print(" ".join(command))
    try:
        completed = subprocess.run(command, cwd=cwd, timeout=timeout)
        return completed.returncode
    except subprocess.TimeoutExpired:
        print(f"Timed out after {timeout} seconds.")
        return 124


def suppress_windows_error_dialogs() -> None:
    """Prevent native child-process failures from opening modal Windows dialogs."""
    if os.name != "nt":
        return

    try:
        import ctypes

        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.GetErrorMode.argtypes = []
        kernel32.GetErrorMode.restype = ctypes.c_uint
        kernel32.SetErrorMode.argtypes = [ctypes.c_uint]
        kernel32.SetErrorMode.restype = ctypes.c_uint
        current_mode = kernel32.GetErrorMode()
        kernel32.SetErrorMode(current_mode | WINDOWS_ERROR_MODE_FLAGS)
    except (AttributeError, OSError):
        # The health checks still have their timeout if this Windows API is
        # unavailable in an unusual Python host.
        return


def prefer_console_executable(candidate: str) -> str:
    """Use Godot's console binary when a windowed binary was supplied."""
    resolved = shutil.which(candidate) or candidate
    path = Path(resolved)
    if path.name.lower().endswith("_console.exe"):
        return str(path)

    if path.suffix.lower() == ".exe":
        console_path = path.with_name(f"{path.stem}_console{path.suffix}")
        if console_path.exists():
            return str(console_path)
    return resolved


def find_godot(explicit_path: str | None) -> str | None:
    if explicit_path:
        return prefer_console_executable(explicit_path)
    env_path = os.environ.get("GODOT")
    if env_path:
        return prefer_console_executable(env_path)
    for name in (
        "Godot_v4.6.2-stable_win64_console.exe",
        "Godot_v4.6-stable_win64_console.exe",
        "Godot_v4.3-stable_win64_console.exe",
        "godot4",
        "godot",
    ):
        found = shutil.which(name)
        if found:
            return prefer_console_executable(found)
    home = Path.home()
    candidates = [
        home / "Desktop" / "Godot_v4.6.2" / "Godot_v4.6.2-stable_win64_console.exe",
        home / "OneDrive" / "Desktop" / "Godot" / "Godot_v4.3-stable_win64_console.exe",
    ]
    for candidate in candidates:
        if candidate.exists():
            return prefer_console_executable(str(candidate))
    return None


def scan_retired_paths(root: Path) -> list[str]:
    hits: list[str] = []
    scan_extensions = {".cfg", ".gd", ".godot", ".import", ".json", ".tres", ".tscn"}
    ignored_parts = {".git", ".godot", "_assets_archive", "__pycache__"}
    for path in root.rglob("*"):
        rel = path.relative_to(root)
        if any(part in ignored_parts for part in rel.parts):
            continue
        if not path.is_file() or path.suffix.lower() not in scan_extensions:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for retired in RETIRED_PATHS:
            if retired in text:
                hits.append(f"{rel}: {retired}")
    return hits


def check_godot_ignored_helper_dirs(root: Path) -> list[str]:
    missing: list[str] = []
    for rel_dir in GODOT_IGNORED_HELPER_DIRS:
        helper_dir = root / rel_dir
        if helper_dir.exists() and not (helper_dir / ".gdignore").exists():
            missing.append(f"{rel_dir}/.gdignore")
    return missing


def check_android_voice_pack_export(root: Path) -> list[str]:
    export_preset = root / "export_presets.cfg"
    if not export_preset.exists():
        return ["export_presets.cfg is missing."]

    include_filter = ""
    in_preset_zero = False
    for raw_line in export_preset.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if line.startswith("["):
            in_preset_zero = line == "[preset.0]"
            continue
        if not in_preset_zero or not line.startswith("include_filter="):
            continue
        include_filter = line.split("=", 1)[1].strip().strip('"')
        break

    if not include_filter:
        return ["Android export preset is missing an include_filter."]

    failures: list[str] = []
    include_entries = [entry.strip().strip('"') for entry in include_filter.split(",") if entry.strip()]
    locale_entries = [
        entry
        for entry in include_entries
        if entry.startswith(ANDROID_VOICE_PACK_TREE) and entry != ANDROID_BASE_SANTA_FALLBACK
    ]
    if locale_entries:
        failures.append(
            "Android export include_filter must not include the locale voice-pack tree: %s"
            % ", ".join(locale_entries[:4])
        )
    if "sounds/voice_over/**" in include_filter:
        failures.append("Android export include_filter is too broad for voice-over assets.")
    if ANDROID_SHARED_VOICE_PATTERN not in include_filter:
        failures.append("Android export include_filter should keep shared voice-over OGG files in the base bundle.")
    if ANDROID_BASE_SANTA_FALLBACK not in include_filter:
        failures.append("Android export include_filter should keep the English Santa fallback clip in the base bundle.")
    return failures


def godot_base_command(godot: str, root: Path, log_name: str) -> list[str]:
    log_path = root / ".godot" / log_name
    log_path.parent.mkdir(parents=True, exist_ok=True)
    return [
        godot,
        "--disable-crash-handler",
        "--headless",
        "--audio-driver",
        "Dummy",
        "--display-driver",
        "headless",
        "--log-file",
        str(log_path),
        "--path",
        str(root),
    ]


def scan_godot_log(root: Path, log_name: str) -> list[str]:
    log_path = root / ".godot" / log_name
    if not log_path.exists():
        return [f"{log_name}: log file was not created."]

    hits: list[str] = []
    for line_number, line in enumerate(log_path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        stripped = line.strip()
        if any(marker in stripped for marker in GODOT_LOG_ERROR_MARKERS):
            hits.append(f"{log_name}:{line_number}: {stripped}")
    return hits


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Farm Chore Friends health checks.")
    parser.add_argument("--root", default=".", help="Project root.")
    parser.add_argument("--godot", default=None, help="Path to Godot console executable.")
    parser.add_argument("--skip-godot", action="store_true", help="Skip Godot headless checks.")
    args = parser.parse_args()

    suppress_windows_error_dialogs()
    root = Path(args.root).resolve()
    failures: list[str] = []

    code = run_step(
        "Asset reference audit",
        [sys.executable, "tools/audit_assets.py", "--fail-on-missing", "--limit", "40"],
        root,
    )
    if code != 0:
        failures.append("Asset reference audit failed.")

    retired_hits = scan_retired_paths(root)
    print("\n== Retired path scan ==")
    if retired_hits:
        for hit in retired_hits:
            print(hit)
        failures.append("Retired paths are still referenced.")
    else:
        print("No retired runtime paths found.")

    missing_ignores = check_godot_ignored_helper_dirs(root)
    print("\n== Godot helper-folder import ignores ==")
    if missing_ignores:
        for missing in missing_ignores:
            print(f"Missing {missing}")
        failures.append("Helper folders are missing .gdignore files.")
    else:
        print("Generated helper/archive folders are ignored by Godot.")

    android_voice_pack_failures = check_android_voice_pack_export(root)
    print("\n== Android voice-pack export filter ==")
    if android_voice_pack_failures:
        for failure in android_voice_pack_failures:
            print(f"Failure: {failure}")
        failures.append("Android export filter no longer matches the locale voice-pack layout.")
    else:
        print("Android export keeps the locale voice packs out of the base bundle.")

    code = run_step(
        "Localization catalogs",
        [sys.executable, "tools/verify_localization.py", "--project-root", str(root)],
        root,
    )
    if code != 0:
        failures.append("Localization catalog verification failed.")
    code = run_step(
        "Voice prompt translation review",
        [sys.executable, "tools/verify_voice_prompt_translations.py", "--project-root", str(root)],
        root,
    )
    if code != 0:
        failures.append("Voice prompt translations are not manually verified.")
    code = run_step(
        "Voice-over catalog",
        [sys.executable, "tools/verify_voice_over.py", "--project-root", str(root)],
        root,
    )
    if code != 0:
        failures.append("Voice-over catalog verification failed.")
    code = run_step(
        "Voice-over OGG container validation",
        [sys.executable, "tools/repair_mislabeled_voice_ogg.py", "--project-root", str(root), "--check-only"],
        root,
    )
    if code != 0:
        failures.append("Mislabeled voice-over OGG files need repair.")

    if not args.skip_godot:
        godot = find_godot(args.godot)
        if not godot:
            failures.append("Godot executable not found. Set GODOT or pass --godot.")
        else:
            project_log = "health_check_project_load.log"
            code = run_step(
                "Godot project load",
                godot_base_command(godot, root, project_log) + ["--quit-after", "5"],
                root,
                GODOT_TIMEOUT_SECONDS,
            )
            if code != 0:
                failures.append("Godot project load failed.")
            project_log_errors = scan_godot_log(root, project_log)
            if project_log_errors:
                print("\nGodot project load log errors:")
                for error in project_log_errors:
                    print(error)
                failures.append("Godot project load logged errors.")

            smoke_log = "health_check_smoke.log"
            code = run_step(
                "Godot scene/progression smoke test",
                godot_base_command(godot, root, smoke_log) + ["-s", "res://tools/godot_project_smoke.gd"],
                root,
                GODOT_TIMEOUT_SECONDS,
            )
            if code != 0:
                failures.append("Godot smoke test failed.")
            smoke_log_errors = scan_godot_log(root, smoke_log)
            if smoke_log_errors:
                print("\nGodot smoke log errors:")
                for error in smoke_log_errors:
                    print(error)
                failures.append("Godot smoke test logged errors.")

    print("\n== Health check summary ==")
    if failures:
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("All health checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
