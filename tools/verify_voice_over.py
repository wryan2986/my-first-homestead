#!/usr/bin/env python3
"""Validate the Farm Chore Friends voice-over catalog.

This verifier does not require OPENAI_API_KEY. By default, missing audio files
are warnings so the catalog can be checked before generation. Pass
--strict-files to fail when any cataloged audio file is missing.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


DEFAULT_CATALOG = Path("sounds") / "voice_over" / "voice_lines.json"
SANTA_LOCALES = ("en-US", "es-US", "fr-FR", "de-DE", "it-IT", "pt-BR")


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify voice-over catalog wiring.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    parser.add_argument("--catalog", default=str(DEFAULT_CATALOG), help="Voice line JSON catalog.")
    parser.add_argument(
        "--strict-files",
        action="store_true",
        help="Fail if any referenced voice-over audio file is missing.",
    )
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    catalog_path = _resolve_project_path(project_root, args.catalog)
    errors: list[str] = []
    warnings: list[str] = []

    if not catalog_path.exists():
        print(f"ERROR: voice catalog not found: {catalog_path}", file=sys.stderr)
        return 1

    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid JSON: {exc}", file=sys.stderr)
        return 1

    voice = catalog.get("voice", {})
    for field in ["model", "voice", "response_format", "instructions"]:
        if not str(voice.get(field, "")).strip():
            errors.append(f"voice.{field} is required")

    response_format = str(voice.get("response_format", "")).strip().lower()
    expected_extension = f".{response_format}" if response_format in {"wav", "ogg", "mp3", "flac"} else ""

    instructions = str(voice.get("instructions", "")).lower()
    for required_phrase in ["same calm adult woman", "toddlers"]:
        if required_phrase not in instructions:
            warnings.append(f"voice.instructions should mention '{required_phrase}'")

    lines = catalog.get("lines", [])
    if not isinstance(lines, list) or not lines:
        errors.append("lines must be a non-empty array")
        lines = []

    keys: set[str] = set()
    text_by_key: dict[str, str] = {}
    missing_files: list[str] = []
    for index, line in enumerate(lines):
        if not isinstance(line, dict):
            errors.append(f"lines[{index}] must be an object")
            continue
        key = str(line.get("key", "")).strip()
        text = str(line.get("text", "")).strip()
        path_text = str(line.get("path", "")).strip()
        if not key:
            errors.append(f"lines[{index}].key is required")
            continue
        if key in keys:
            errors.append(f"duplicate key: {key}")
        keys.add(key)
        text_by_key[key] = text
        if not text:
            errors.append(f"{key}: text is required")
        if not path_text:
            errors.append(f"{key}: path is required")
            continue
        if not path_text.startswith("res://sounds/voice_over/"):
            warnings.append(f"{key}: path should live under res://sounds/voice_over/")
        if expected_extension and not path_text.endswith(expected_extension):
            warnings.append(f"{key}: expected {expected_extension} output")
        output_path = _resolve_project_path(project_root, path_text)
        if not output_path.exists():
            missing_files.append(path_text)

    aliases = catalog.get("aliases", {})
    if aliases and not isinstance(aliases, dict):
        errors.append("aliases must be an object")
        aliases = {}
    if isinstance(aliases, dict):
        for alias_key, target_key in aliases.items():
            alias = str(alias_key).strip()
            target = str(target_key).strip()
            if not alias:
                errors.append("alias key cannot be empty")
            if target not in keys:
                errors.append(f"alias {alias} points to missing target {target}")

    _check_santa_greeting_assets(project_root, warnings, errors)
    _check_locale_catalogs(project_root, warnings, errors, args.strict_files)

    _check_completion_group(keys, text_by_key, "eggs")
    _check_completion_group(keys, text_by_key, "milking")
    _check_completion_group(keys, text_by_key, "feeding")
    _check_completion_group(keys, text_by_key, "brushing")
    _check_completion_group(keys, text_by_key, "garden")

    if missing_files:
        message = "missing %d voice-over audio file(s); run tools/generate_voice_over.py" % len(missing_files)
        if args.strict_files:
            errors.append(message)
        else:
            warnings.append(message)

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    print(
        "Voice-over catalog: %d lines, %d aliases, %d missing files."
        % (len(keys), len(aliases) if isinstance(aliases, dict) else 0, len(missing_files))
    )
    return 1 if errors else 0


def _check_locale_catalogs(project_root: Path, warnings: list[str], errors: list[str], strict_files: bool) -> None:
    locale_root = project_root / "sounds" / "voice_over" / "locales"
    if not locale_root.exists():
        warnings.append("locale voice-over folder is missing")
        return
    for catalog_path in sorted(locale_root.glob("*/voice_lines.json")):
        locale = catalog_path.parent.name
        try:
            catalog = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as exc:
            errors.append(f"{catalog_path}: invalid JSON: {exc}")
            continue
        lines = catalog.get("lines", [])
        if not isinstance(lines, list):
            errors.append(f"{catalog_path}: lines must be an array")
            continue
        for index, line in enumerate(lines):
            if not isinstance(line, dict):
                errors.append(f"{catalog_path}: lines[{index}] must be an object")
                continue
            key = str(line.get("key", "")).strip() or f"lines[{index}]"
            path_text = str(line.get("path", "")).strip()
            if not path_text:
                errors.append(f"{catalog_path}: {key}: path is required")
                continue
            expected_prefix = f"res://sounds/voice_over/locales/{locale}/"
            if locale != "en" and not path_text.startswith(expected_prefix):
                errors.append(f"{catalog_path}: {key}: localized path must start with {expected_prefix}")
            output_path = _resolve_project_path(project_root, path_text)
            if not output_path.exists():
                message = f"{catalog_path}: {key}: missing localized audio file {path_text}"
                if strict_files:
                    errors.append(message)
                else:
                    warnings.append(message)


def _check_completion_group(keys: set[str], text_by_key: dict[str, str], prefix: str) -> None:
    expected = [f"{prefix}_complete_{index}" for index in range(5)]
    missing = [key for key in expected if key not in keys]
    if missing:
        print(f"WARNING: {prefix} completion group missing: {', '.join(missing)}")
    for key in expected:
        text = text_by_key.get(key, "")
        if key in keys and not text.endswith("."):
            print(f"WARNING: {key} should end with a period for calmer TTS pacing")


def _check_santa_greeting_assets(project_root: Path, warnings: list[str], errors: list[str]) -> None:
    for locale in SANTA_LOCALES:
        localized_path = project_root / "sounds" / "voice_over" / "locales" / locale / "santa_full_greeting.ogg"
        legacy_path = project_root / "sounds" / "voice_over" / "santa" / locale / "santa_full_greeting.ogg"
        if not localized_path.exists():
            errors.append(f"missing Santa greeting clip: res://sounds/voice_over/locales/{locale}/santa_full_greeting.ogg")
        if legacy_path.exists():
            warnings.append(f"legacy Santa clip still present: res://sounds/voice_over/santa/{locale}/santa_full_greeting.ogg")


def _resolve_project_path(project_root: Path, path_text: str) -> Path:
    if path_text.startswith("res://"):
        return project_root / path_text.replace("res://", "", 1)
    path = Path(path_text)
    if path.is_absolute():
        return path
    return project_root / path


if __name__ == "__main__":
    raise SystemExit(main())
