#! /usr/bin/env python3
"""Compare TTS voices from Kokoro, Google Chirp 3 HD, ElevenLabs, and Cartesia."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import random
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

from providers.base import (
    COMMON_CHANNELS,
    COMMON_FORMAT,
    COMMON_SAMPLE_RATE,
    COMMON_SUFFIX,
    GenerationResult,
    SynthesisSettings,
    VoiceInfo,
    build_output_filename,
    measure_audio,
    sanitise_filename,
)
from providers.kokoro_provider import KokoroProvider, DEFAULT_VOICE as KOKORO_DEFAULT_VOICE, DEFAULT_SPEED as KOKORO_DEFAULT_SPEED
from providers.google_provider import GoogleProvider
from providers.elevenlabs_provider import ElevenLabsProvider
from providers.cartesia_provider import CartesiaProvider

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
OUTPUT_DIR = Path(__file__).resolve().parent / "output"
ORIGINALS_DIR = OUTPUT_DIR / "originals"
NORMALIZED_DIR = OUTPUT_DIR / "normalized"
BLIND_TEST_DIR = OUTPUT_DIR / "blind_test"

MAX_CLOUD_CHARS = 10_000
MAX_CLOUD_CHARS_LARGE = 100_000


def _load_dotenv() -> None:
    dotenv_path = Path(__file__).resolve().parent / ".env"
    if dotenv_path.exists():
        for line in dotenv_path.read_text(encoding="utf-8-sig").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            key = key.strip()
            val = val.strip().strip("\"'")
            if key and val and not os.environ.get(key):
                os.environ[key] = val


def _get_providers() -> dict[str, Any]:
    return {
        "kokoro": KokoroProvider(),
        "google": GoogleProvider(),
        "elevenlabs": ElevenLabsProvider(),
        "cartesia": CartesiaProvider(),
    }


def _resolve_voice_name(provider_name: str, voice_id: str, voices: list[VoiceInfo]) -> str:
    for v in voices:
        if v.voice_id == voice_id:
            return v.name
    return voice_id


# ── check ──────────────────────────────────────────────────────────────────


def cmd_check(args: argparse.Namespace) -> int:
    _load_dotenv()
    providers = _get_providers()
    print("Voice Comparison — Provider Check")
    print("=" * 50)

    for name, prov in providers.items():
        configured = prov.is_configured()
        status = "CONFIGURED" if configured else "NOT CONFIGURED"
        print(f"\n{name}:")
        print(f"  Status: {status}")
        if name == "kokoro":
            print(f"  Voice:  {KOKORO_DEFAULT_VOICE}")
            print(f"  Speed:  {KOKORO_DEFAULT_SPEED}")
            print(f"  Path:   ~/ai-tools/kokoro-tts (WSL; override with KOKORO_WSL_DIR)")
            print(f"  Output: 24000 Hz WAV via WSL Kokoro pipeline")
        elif name == "google":
            _check_google()
        elif name == "elevenlabs":
            _check_key("ELEVENLABS_API_KEY")
        elif name == "cartesia":
            _check_key("CARTESIA_API_KEY")

    print("\n" + "=" * 50)
    print("To configure missing providers:")
    print("  ElevenLabs: set ELEVENLABS_API_KEY in .env or environment")
    print("  Cartesia:   set CARTESIA_API_KEY in .env or environment")
    print("  Google:     run: gcloud auth application-default login")
    return 0


def _check_google() -> None:
    gcloud = _find_gcloud()
    if not gcloud:
        print("  gcloud CLI not found on PATH")
        return
    try:
        result = subprocess.run([gcloud, "config", "get-value", "project"],
                                capture_output=True, text=True, timeout=15)
        project = result.stdout.strip()
        print(f"  Project:  {project if project else '(not set)'}")
    except Exception:
        print("  Project:  (could not check)")

    try:
        result = subprocess.run(
            [gcloud, "auth", "application-default", "print-access-token"],
            capture_output=True, text=True, timeout=15,
        )
        if result.returncode == 0:
            print("  ADC:      OK")
        else:
            print("  ADC:      NOT CONFIGURED")
            print("  Run:      gcloud auth application-default login")
    except Exception:
        print("  ADC:      NOT CONFIGURED")

    try:
        result = subprocess.run(
            [gcloud, "services", "list", "--enabled",
             "--filter=name:texttospeech.googleapis.com",
             "--format=value(name)"],
            capture_output=True, text=True, timeout=15,
        )
        if "texttospeech" in result.stdout:
            print("  TTS API:  Enabled")
        else:
            print("  TTS API:  DISABLED — run: gcloud services enable texttospeech.googleapis.com")
    except Exception:
        print("  TTS API:  (could not check)")


def _check_key(name: str) -> None:
    val = os.environ.get(name, "")
    if val:
        print(f"  {name}: set ({len(val)} chars)")
    else:
        print(f"  {name}: NOT SET")


def _find_gcloud() -> str | None:
    candidates = [
        "gcloud.cmd",
        "gcloud",
        str(Path(os.environ.get("LOCALAPPDATA", "")) / "Google" / "Cloud SDK" / "google-cloud-sdk" / "bin" / "gcloud.cmd"),
    ]
    for c in candidates:
        try:
            result = subprocess.run([c, "--version"], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                return c
        except Exception:
            continue
    return None


# ── list-voices ────────────────────────────────────────────────────────────


def cmd_list_voices(args: argparse.Namespace) -> int:
    _load_dotenv()
    providers = _get_providers()

    if args.provider:
        names = [args.provider]
    else:
        names = list(providers.keys())

    for name in names:
        prov = providers.get(name)
        if prov is None:
            print(f"Unknown provider: {name}")
            continue
        print(f"\n=== {name} voices ===")
        voices = prov.list_voices()
        if not voices:
            print("  (none or not configured)")
            continue
        for v in voices:
            hd = " [Chirp 3 HD]" if getattr(v, "is_chirp_hd", False) else ""
            print(f"  {v.voice_id:<50s} {v.gender:<8s} {','.join(v.language_codes):<20s} {v.model}{hd}")
    return 0


# ── generate ───────────────────────────────────────────────────────────────


def cmd_generate(args: argparse.Namespace) -> int:
    _load_dotenv()
    providers = _get_providers()

    manifest_path = Path(args.manifest)
    if not manifest_path.exists():
        print(f"Error: Manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        print(f"Error: Invalid manifest: {exc}", file=sys.stderr)
        return 1

    samples = manifest.get("samples", [])
    if not samples:
        print("Error: Manifest has no samples.", file=sys.stderr)
        return 1

    selected_providers: list[str] = []
    if args.providers:
        for name in args.providers.split(","):
            name = name.strip().lower()
            if name in providers:
                selected_providers.append(name)
            else:
                print(f"Warning: Unknown provider '{name}', skipping", file=sys.stderr)
    else:
        selected_providers = list(providers.keys())

    total_chars = sum(len(s["text"]) for s in samples)
    total_files = len(samples) * len(selected_providers)

    if args.dry_run:
        print(f"\nDRY RUN — no API calls will be made.\n")
        print(f"Manifest:    {manifest_path.name}")
        print(f"Samples:     {len(samples)}")
        print(f"Providers:   {', '.join(selected_providers)}")
        print(f"Total files: {total_files}")
        print(f"Total chars: {total_chars}")

        cloud_chars = sum(
            len(s["text"]) for s in samples
            for p in selected_providers if p in ("google", "elevenlabs", "cartesia")
        )
        print(f"Cloud chars: {cloud_chars} (billable)")

        if args.output_dir:
            out = Path(args.output_dir)
            print(f"Output dir:  {out.resolve()}")
        else:
            out = ORIGINALS_DIR
            print(f"Output dir:  {out.resolve()}")

        print(f"\nFiles that would be generated:")
        for prov_name in selected_providers:
            prov = providers[prov_name]
            voices = _resolve_voices_for_provider(prov, prov_name, args)
            for s in samples:
                for vid in voices:
                    vname = _resolve_voice_name(prov_name, vid, prov.list_voices())
                    fname = build_output_filename(prov_name, vname, s["id"])
                    print(f"  {prov_name:<12s} {vname:<30s} {fname}")

        print(f"\nCloud characters: {cloud_chars}")
        if cloud_chars > MAX_CLOUD_CHARS and not args.allow_large_run:
            print(f"\n⚠  Cloud characters exceed {MAX_CLOUD_CHARS}. Pass --allow-large-run to proceed.")
        print(f"\nDry run complete. Run without --dry-run to generate.")
        return 0

    if not args.yes:
        cloud_chars = sum(
            len(s["text"]) for s in samples
            for p in selected_providers if p in ("google", "elevenlabs", "cartesia")
        )
        print(f"\nAbout to generate {total_files} files ({total_chars} chars, {cloud_chars} cloud chars).")
        print(f"Providers: {', '.join(selected_providers)}")
        if cloud_chars > MAX_CLOUD_CHARS and not args.allow_large_run:
            print(f"\nError: Cloud characters ({cloud_chars}) exceed {MAX_CLOUD_CHARS}.", file=sys.stderr)
            print("Use --allow-large-run or reduce samples.", file=sys.stderr)
            return 1
        try:
            response = input("Continue? [y/N] ").strip().lower()
            if response != "y":
                print("Cancelled.")
                return 0
        except EOFError:
            print("\nNon-interactive shell; pass --yes to skip confirmation.")
            return 1

    settings = SynthesisSettings(
        language_code=args.language_code,
        speaking_rate=args.rate,
    )

    if args.output_dir:
        originals_dir = Path(args.output_dir)
    else:
        originals_dir = ORIGINALS_DIR

    results: list[GenerationResult] = []
    exit_code = 0

    for prov_name in selected_providers:
        prov = providers[prov_name]
        if not prov.is_configured():
            print(f"\n{prov_name}: NOT CONFIGURED — skipping")
            continue

        voices_to_use = _resolve_voices_for_provider(prov, prov_name, args)
        print(f"\n{prov_name}: generating {len(samples)} samples × {len(voices_to_use)} voice(s)")

        for voice_id in voices_to_use:
            vname = _resolve_voice_name(prov_name, voice_id, prov.list_voices())
            for s in samples:
                sid = s["id"]
                text = s["text"]
                fname = build_output_filename(prov_name, vname, sid)
                out_path = originals_dir / prov_name / fname
                out_path.parent.mkdir(parents=True, exist_ok=True)

                if out_path.exists() and not args.overwrite:
                    print(f"  [skip] {fname}")
                    dur, sr, ch, sz = measure_audio(out_path)
                    results.append(GenerationResult(
                        provider=prov_name, voice_id=voice_id, voice_name=vname,
                        model="", sample_id=sid, text=text,
                        output_path=out_path, format=COMMON_FORMAT,
                        sample_rate=sr or COMMON_SAMPLE_RATE, channels=ch or COMMON_CHANNELS,
                        duration_seconds=dur, file_size_bytes=sz,
                        generation_time_ms=0, success=True,
                        settings=settings, character_count=len(text),
                    ))
                    continue

                result = prov.synthesize(text, voice_id, out_path, settings)
                result.sample_id = sid
                if hasattr(result, "voice_name") and result.voice_name == result.voice_id:
                    object.__setattr__(result, "voice_name", vname)
                results.append(result)
                if result.success:
                    print(f"  [ok]   {fname} ({result.duration_seconds:.1f}s, {result.file_size_bytes} bytes)")
                else:
                    print(f"  [FAIL] {fname}: {result.error_message[:80]}", file=sys.stderr)
                    exit_code = 1

    _write_results_json(results, originals_dir)
    _print_summary(results)
    return exit_code


def _resolve_voices_for_provider(prov: Any, prov_name: str, args: argparse.Namespace) -> list[str]:
    if prov_name == "kokoro":
        return [KOKORO_DEFAULT_VOICE]
    elif prov_name == "google":
        if args.google_voices:
            return [v.strip() for v in args.google_voices.split(",")]
        return ["en-US-Chirp3-HD-Aoede"]
    elif prov_name == "elevenlabs":
        if args.elevenlabs_voices:
            return [v.strip() for v in args.elevenlabs_voices.split(",")]
        voices = prov.list_voices()
        if voices:
            return [voices[0].voice_id]
        return ["21m00Tcm4TlvDq8ikWAM"]
    elif prov_name == "cartesia":
        if args.cartesia_voices:
            return [v.strip() for v in args.cartesia_voices.split(",")]
        voices = prov.list_voices()
        if voices:
            return [voices[0].voice_id]
        return ["a8871e61-4b73-4a8a-9341-7cc3be7fcfb9"]
    return []


def _write_results_json(results: list[GenerationResult], output_dir: Path) -> None:
    data = []
    for r in results:
        data.append({
            "provider": r.provider,
            "voice_id": r.voice_id,
            "voice_name": r.voice_name,
            "model": r.model,
            "sample_id": r.sample_id,
            "text": r.text,
            "output_path": str(r.output_path),
            "format": r.format,
            "sample_rate": r.sample_rate,
            "channels": r.channels,
            "duration_seconds": r.duration_seconds,
            "file_size_bytes": r.file_size_bytes,
            "generation_time_ms": r.generation_time_ms,
            "success": r.success,
            "error_message": r.error_message,
            "character_count": r.character_count,
        })
    path = output_dir / ".." / "comparison.json"
    path = path.resolve()
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nMetadata: {path}")


def _print_summary(results: list[GenerationResult]) -> None:
    total = len(results)
    ok = sum(1 for r in results if r.success)
    fail = total - ok
    print(f"\nSummary: {ok} ok, {fail} failed of {total}")

    if ok:
        by_provider: dict[str, int] = {}
        by_provider_chars: dict[str, int] = {}
        for r in results:
            if r.success:
                by_provider[r.provider] = by_provider.get(r.provider, 0) + 1
                by_provider_chars[r.provider] = by_provider_chars.get(r.provider, 0) + r.character_count
        for p, count in sorted(by_provider.items()):
            chars = by_provider_chars[p]
            print(f"  {p}: {count} files, {chars} chars")


# ── normalize ──────────────────────────────────────────────────────────────


def cmd_normalize(args: argparse.Namespace) -> int:
    originals = ORIGINALS_DIR
    if not originals.exists():
        print(f"Error: No originals directory at {originals}", file=sys.stderr)
        return 1

    target_lufs = args.lufs
    normalized_root = NORMALIZED_DIR
    normalized_root.mkdir(parents=True, exist_ok=True)

    files_found = sorted(originals.rglob("*.wav"))
    if not files_found:
        print("No WAV files found in originals/")
        return 1

    print(f"Normalizing {len(files_found)} files to {target_lufs} LUFS...")
    converted = 0
    failed = 0

    for src in files_found:
        rel = src.relative_to(originals)
        dst = normalized_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)

        if dst.exists() and not args.overwrite:
            print(f"  [skip] {rel}")
            converted += 1
            continue

        try:
            _normalize_audio(src, dst, target_lufs)
            print(f"  [ok]   {rel}")
            converted += 1
        except Exception as exc:
            print(f"  [FAIL] {rel}: {exc}", file=sys.stderr)
            failed += 1
            shutil.copy2(src, dst)

    print(f"\nNormalized: {converted}, failed: {failed}")
    return 0 if failed == 0 else 1


def _normalize_audio(src: Path, dst: Path, target_lufs: float = -16.0) -> None:
    try:
        subprocess.run(
            ["wsl.exe", "ffmpeg", "-y", "-i", _wsl_path(src),
             "-af", f"loudnorm=I={target_lufs}:LRA=7:TP=-1.5:print_format=json",
             "-ac", "1", "-ar", str(COMMON_SAMPLE_RATE),
             "-c:a", "pcm_s16le", _wsl_path(dst)],
            capture_output=True, text=True, timeout=120, check=True,
        )
    except Exception:
        subprocess.run(
            ["ffmpeg", "-y", "-i", str(src),
             "-af", f"loudnorm=I={target_lufs}:LRA=7:TP=-1.5",
             "-ac", "1", "-ar", str(COMMON_SAMPLE_RATE),
             "-c:a", "pcm_s16le", str(dst)],
            capture_output=True, text=True, timeout=120, check=True,
        )


def _wsl_path(p: Path) -> str:
    drive = p.drive[0].lower()
    rest = str(p.relative_to(p.anchor)).replace("\\", "/")
    return f"/mnt/{drive}/{rest}"


# ── make-blind-test ────────────────────────────────────────────────────────


def cmd_make_blind_test(args: argparse.Namespace) -> int:
    normalized = NORMALIZED_DIR
    if not normalized.exists():
        print(f"Error: No normalized directory at {normalized}", file=sys.stderr)
        return 1

    seed = args.seed
    random.seed(seed)
    blind_dir = BLIND_TEST_DIR
    blind_dir.mkdir(parents=True, exist_ok=True)

    files = sorted(normalized.rglob("*.wav"))
    if not files:
        print("No WAV files found in normalized/")
        return 1

    random.shuffle(files)

    mapping: dict[str, dict[str, Any]] = {}
    for idx, src in enumerate(files, start=1):
        blind_name = f"sample_{idx:03d}{COMMON_SUFFIX}"
        dst = blind_dir / blind_name
        shutil.copy2(src, dst)
        rel = src.relative_to(normalized)
        parts = str(rel).replace("\\", "/").split("/")
        provider_name = parts[0] if len(parts) > 0 else "unknown"
        voice_name = parts[1].replace(COMMON_SUFFIX, "").split("__")[1] if len(parts) > 1 and "__" in parts[1] else "unknown"
        mapping[blind_name] = {
            "blind_id": blind_name.replace(COMMON_SUFFIX, ""),
            "original_path": str(rel),
            "provider": provider_name,
            "voice": voice_name,
        }

    key_path = OUTPUT_DIR / "blind_test_key.json"
    key_path.write_text(json.dumps(mapping, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    csv_path = OUTPUT_DIR / "comparison.csv"
    with open(csv_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow([
            "blind_id", "sample_text",
            "naturalness_1_to_5", "warmth_1_to_5", "clarity_1_to_5",
            "toddler_appropriateness_1_to_5", "consistency_1_to_5",
            "favorite", "notes",
        ])
        for blind_name, info in sorted(mapping.items()):
            writer.writerow([
                info["blind_id"], "",
                "", "", "", "", "",
                "", "",
            ])

    print(f"Blind test: {len(files)} files -> {blind_dir}")
    print(f"Key:        {key_path}")
    print(f"CSV:        {csv_path}")
    print(f"Seed:       {seed}")
    return 0


# ── report ─────────────────────────────────────────────────────────────────


def cmd_report(args: argparse.Namespace) -> int:
    json_path = OUTPUT_DIR / "comparison.json"
    if not json_path.exists():
        print("No comparison.json found. Run generate first.", file=sys.stderr)
        return 1

    data = json.loads(json_path.read_text(encoding="utf-8"))
    if not data:
        print("Empty comparison data.")
        return 1

    print("Voice Comparison Report")
    print("=" * 60)
    by_provider: dict[str, list[dict]] = {}
    for entry in data:
        by_provider.setdefault(entry["provider"], []).append(entry)

    for prov_name, entries in sorted(by_provider.items()):
        ok = [e for e in entries if e["success"]]
        fail = [e for e in entries if not e["success"]]
        total_chars = sum(e["character_count"] for e in ok)
        total_dur = sum(e["duration_seconds"] for e in ok)
        total_time = sum(e["generation_time_ms"] for e in ok)
        print(f"\n{prov_name}:")
        print(f"  Files:     {len(ok)} ok, {len(fail)} failed")
        print(f"  Chars:     {total_chars}")
        print(f"  Duration:  {total_dur:.1f}s audio")
        print(f"  Gen time:  {total_time / 1000:.1f}s")
        if ok:
            voices = set(e["voice_name"] for e in ok)
            models = set(e["model"] for e in ok)
            print(f"  Voices:    {', '.join(sorted(voices))}")
            print(f"  Models:    {', '.join(sorted(models))}")
        if fail:
            print(f"  Errors:")
            for e in fail[:3]:
                print(f"    {e['sample_id']}: {e['error_message'][:100]}")

    print(f"\nTotal entries: {len(data)}")
    return 0


# ── main ───────────────────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare TTS voices for farm game narration.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_check = sub.add_parser("check", help="Check provider configuration")
    p_check.set_defaults(func=cmd_check)

    p_list = sub.add_parser("list-voices", help="List available voices")
    p_list.add_argument("--provider", choices=["kokoro", "google", "elevenlabs", "cartesia"],
                        help="Only list voices for this provider")
    p_list.set_defaults(func=cmd_list_voices)

    p_gen = sub.add_parser("generate", help="Generate comparison samples")
    p_gen.add_argument("--manifest", default=str(Path(__file__).resolve().parent / "comparison_manifest.json"),
                       help="Path to manifest JSON")
    p_gen.add_argument("--providers", default="",
                       help="Comma-separated: kokoro,google,elevenlabs,cartesia")
    p_gen.add_argument("--output-dir", default="",
                       help="Output directory for original files (default: output/originals/)")
    p_gen.add_argument("--language-code", default="en-US")
    p_gen.add_argument("--rate", type=float, default=0.9, help="Speaking rate")
    p_gen.add_argument("--overwrite", action="store_true", help="Regenerate existing files")
    p_gen.add_argument("--dry-run", action="store_true", help="Validate without generating")
    p_gen.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    p_gen.add_argument("--allow-large-run", action="store_true",
                       help=f"Allow >{MAX_CLOUD_CHARS} cloud characters")
    p_gen.add_argument("--google-voices", default="",
                       help="Comma-separated Google voice IDs")
    p_gen.add_argument("--elevenlabs-voices", default="",
                       help="Comma-separated ElevenLabs voice IDs")
    p_gen.add_argument("--cartesia-voices", default="",
                       help="Comma-separated Cartesia voice IDs")
    p_gen.set_defaults(func=cmd_generate)

    p_norm = sub.add_parser("normalize", help="Normalize loudness of generated files")
    p_norm.add_argument("--lufs", type=float, default=-16.0,
                        help="Target LUFS loudness (default: -16)")
    p_norm.add_argument("--overwrite", action="store_true")
    p_norm.set_defaults(func=cmd_normalize)

    p_blind = sub.add_parser("make-blind-test", help="Create randomized blind listening test")
    p_blind.add_argument("--seed", type=int, default=42, help="Random seed (default: 42)")
    p_blind.set_defaults(func=cmd_make_blind_test)

    p_report = sub.add_parser("report", help="Print generation report from saved metadata")
    p_report.set_defaults(func=cmd_report)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
