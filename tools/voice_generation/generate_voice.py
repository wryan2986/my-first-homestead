#! /usr/bin/env python3
"""Generate prerecorded narration audio using Google Cloud Chirp 3 HD.

Development-time asset generator for Farm Chore Friends.
Uses Google Cloud Text-to-Speech with Application Default Credentials.
The shipped game must not contain credentials or call Google Cloud APIs.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    from google.cloud import texttospeech
    from google.cloud.texttospeech import (
        AudioConfig,
        AudioEncoding,
        SsmlVoiceGender,
        SynthesisInput,
        VoiceSelectionParams,
    )
except ImportError:
    print(
        "Missing google-cloud-texttospeech library.\n"
        "Run: pip install -r tools\\voice_generation\\requirements.txt",
        file=sys.stderr,
    )
    sys.exit(1)

DEFAULT_VOICE = "en-US-Chirp3-HD-Aoede"
DEFAULT_LANGUAGE_CODE = "en-US"
DEFAULT_SPEAKING_RATE = 0.9
DEFAULT_OUTPUT_DIR = "sounds/voice_over"
SAMPLE_RATE = 24000

_SSML_ESCAPE_TABLE = str.maketrans({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&apos;"})

class _SynthesizeError(Exception):
    pass


def _escape_xml(text: str) -> str:
    return text.translate(_SSML_ESCAPE_TABLE)


def _build_ssml(text: str, speaking_rate: float) -> str:
    rate_str = f"{speaking_rate:.2f}"
    escaped = _escape_xml(text)
    return f"<speak><prosody rate='{rate_str}'>{escaped}</prosody></speak>"


def _project_root_from_args(args: argparse.Namespace) -> Path:
    return Path(args.project_root).resolve()


def _resolve_output_dir(project_root: Path, output_dir_arg: str, allow_outside: bool) -> Path:
    candidate = Path(output_dir_arg)
    if not candidate.is_absolute():
        candidate = project_root / candidate
    candidate = candidate.resolve()
    if not allow_outside and not _is_subpath(candidate, project_root):
        print(
            f"Error: Output path {candidate} is outside the project root {project_root}.\n"
            "Use --allow-outside-repo to permit this, or choose a path inside the project.",
            file=sys.stderr,
        )
        sys.exit(1)
    return candidate


def _is_subpath(child: Path, parent: Path) -> bool:
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False


def _validate_manifest_entry(entry: Any, index: int) -> dict:
    if not isinstance(entry, dict):
        print(f"Error: Manifest entry {index} is not a JSON object.", file=sys.stderr)
        sys.exit(1)
    entry_id = entry.get("id", "")
    text = entry.get("text", "")
    if not isinstance(entry_id, str) or not entry_id.strip():
        print(f"Error: Manifest entry {index} missing valid 'id' string.", file=sys.stderr)
        sys.exit(1)
    if not isinstance(text, str) or not text.strip():
        print(f"Error: Manifest entry {index} ('{entry_id}') missing valid 'text' string.", file=sys.stderr)
        sys.exit(1)
    return {
        "id": entry_id.strip(),
        "text": text.strip(),
        "voice": entry.get("voice", "").strip() or None,
        "language_code": entry.get("language_code", "").strip() or None,
        "speaking_rate": entry.get("speaking_rate", None),
        "filename": entry.get("filename", "").strip() or None,
    }


def _load_manifest(path: Path) -> list[dict]:
    if not path.exists():
        print(f"Error: Manifest not found: {path}", file=sys.stderr)
        sys.exit(1)
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        print(f"Error: Invalid JSON in {path}: {exc}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, list):
        print(f"Error: Manifest must be a JSON array at {path}", file=sys.stderr)
        sys.exit(1)
    return [_validate_manifest_entry(e, i) for i, e in enumerate(data)]


def _sanitise_filename(id_str: str) -> str:
    sanitised = re.sub(r"[^a-z0-9_]+", "_", id_str.lower())
    return sanitised.strip("_")


def _get_ogg_path(wav_path: Path) -> Path:
    return wav_path.with_suffix(".ogg")


def _convert_to_ogg(wav_path: Path, project_root: Path) -> Path:
    ogg_path = _get_ogg_path(wav_path)
    if ogg_path.exists():
        ogg_path.unlink()

    def _wsl_path(p: Path) -> str:
        drive = p.drive[0].lower()
        rest = str(p.relative_to(p.anchor)).replace("\\", "/")
        return f"/mnt/{drive}/{rest}"

    cmd = [
        "wsl.exe", "ffmpeg", "-y",
        "-i", _wsl_path(wav_path),
        "-ac", "1",
        "-ar", "44100",
        "-c:a", "libvorbis",
        "-q:a", "4",
        _wsl_path(ogg_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        print(f"  Warning: ffmpeg OGG conversion failed: {result.stderr.strip()}", file=sys.stderr)
        return wav_path
    print(f"  Converted to OGG: {ogg_path}")
    return ogg_path


def _list_voices(client: texttospeech.TextToSpeechClient) -> None:
    try:
        response = client.list_voices(language_code="en-US")
    except Exception as exc:
        print(f"Error listing voices: {exc}", file=sys.stderr)
        sys.exit(1)
    chirp_voices = []
    other_voices = []
    for voice in response.voices:
        name = voice.name
        ssml_gender = SsmlVoiceGender(voice.ssml_gender).name if voice.ssml_gender else "UNKNOWN"
        langs = ", ".join(voice.language_codes)
        entry = {"name": name, "gender": ssml_gender, "languages": langs, "is_chirp_hd": "Chirp3-HD" in name}
        if entry["is_chirp_hd"]:
            chirp_voices.append(entry)
        else:
            other_voices.append(entry)
    print(f"\nChirp 3 HD voices (en-US):")
    for v in chirp_voices:
        print(f"  {v['name']:<45s} {v['gender']:<8s} {v['languages']}")
    print(f"\nOther en-US voices (first 20):")
    for v in other_voices[:20]:
        print(f"  {v['name']:<45s} {v['gender']:<8s} {v['languages']}")
    remaining = len(other_voices) - 20
    if remaining > 0:
        print(f"  ... and {remaining} more")


def _synthesize(client: texttospeech.TextToSpeechClient, entry: dict, output_dir: Path,
                default_voice: str, default_language_code: str, default_rate: float,
                overwrite: bool, dry_run: bool, do_ogg: bool, project_root: Path) -> Path | None:
    entry_id = entry["id"]
    text = entry["text"]
    voice_name = entry.get("voice") or default_voice
    language_code = entry.get("language_code") or default_language_code
    speaking_rate = entry.get("speaking_rate") if entry.get("speaking_rate") is not None else default_rate
    filename = entry.get("filename") or _sanitise_filename(entry_id)

    wav_path = output_dir / f"{filename}.wav"

    if wav_path.exists() and not overwrite:
        if dry_run:
            print(f"  Would skip (exists): {filename}")
        else:
            print(f"  Skip (exists): {filename}")
        if do_ogg:
            ogg_path = _get_ogg_path(wav_path)
            if ogg_path.exists():
                if overwrite:
                    return ogg_path
                print(f"  Skip OGG (exists): {ogg_path.name}")
                return ogg_path
            if dry_run:
                print(f"  Would convert to OGG: {ogg_path.name}")
                return None
            return _convert_to_ogg(wav_path, project_root)
        return None

    if dry_run:
        print(f"  Would generate: {filename}.wav")
        print(f"    Voice: {voice_name}, Language: {language_code}, Rate: {speaking_rate}")
        print(f"    Text: {text[:80]}")
        if do_ogg:
            print(f"    Would convert to OGG: {filename}.ogg")
        return None

    ssml = _build_ssml(text, speaking_rate)
    input_config = SynthesisInput(ssml=ssml)
    voice_config = VoiceSelectionParams(
        language_code=language_code,
        name=voice_name,
    )
    audio_config = AudioConfig(
        audio_encoding=AudioEncoding.LINEAR16,
        speaking_rate=speaking_rate,
        sample_rate_hertz=SAMPLE_RATE,
    )

    try:
        response = client.synthesize_speech(
            request={"input": input_config, "voice": voice_config, "audio_config": audio_config}
        )
    except Exception as exc:
        print(f"  Error generating '{entry_id}': {exc}", file=sys.stderr)
        raise _SynthesizeError(str(exc)) from exc

    output_dir.mkdir(parents=True, exist_ok=True)
    wav_path.write_bytes(response.audio_content)
    print(f"  Generated: {wav_path}")

    if do_ogg:
        return _convert_to_ogg(wav_path, project_root)

    return wav_path


def _run() -> int:
    parser = argparse.ArgumentParser(
        description="Generate prerecorded narration using Google Cloud Chirp 3 HD.",
    )
    source_group = parser.add_argument_group("Source").add_mutually_exclusive_group()
    source_group.add_argument("--text", help="Narration text to speak")
    source_group.add_argument("--manifest", help="JSON manifest file with narration entries")
    source_group.add_argument("--list-voices", action="store_true", help="List available Chirp 3 HD voices and exit")

    parser.add_argument("--id", dest="prompt_id", help="Prompt key / stable narration ID (required with --text)")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help="Output directory (default: sounds/voice_over)")
    parser.add_argument("--voice", default=DEFAULT_VOICE, help=f"Voice name (default: {DEFAULT_VOICE})")
    parser.add_argument("--language-code", default=DEFAULT_LANGUAGE_CODE, help=f"Language code (default: {DEFAULT_LANGUAGE_CODE})")
    parser.add_argument("--rate", type=float, default=DEFAULT_SPEAKING_RATE,
                        help=f"Speaking rate 0.25-4.0 (default: {DEFAULT_SPEAKING_RATE})")
    parser.add_argument("--project-root", default=".",
                        help="Godot project root directory (default: current working directory)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing output files")
    parser.add_argument("--dry-run", action="store_true", help="Validate and plan without generating audio")
    parser.add_argument("--ogg", action="store_true", help="Convert WAV output to OGG Vorbis via ffmpeg")
    parser.add_argument("--allow-outside-repo", action="store_true",
                        help="Allow output directory outside the project root")

    args = parser.parse_args()

    if args.list_voices:
        try:
            client = texttospeech.TextToSpeechClient()
        except Exception as exc:
            print(f"Error creating TTS client: {exc}", file=sys.stderr)
            print("Make sure ADC is configured: gcloud auth application-default login", file=sys.stderr)
            return 1
        _list_voices(client)
        return 0

    if not args.text and not args.manifest:
        parser.error("Provide --text (with --id) or --manifest")

    if args.text and not args.prompt_id:
        parser.error("--id is required when using --text")

    project_root = _project_root_from_args(args)
    output_dir = _resolve_output_dir(project_root, args.output_dir, args.allow_outside_repo)

    entries: list[dict] = []
    if args.manifest:
        manifest_path = (project_root / args.manifest) if not Path(args.manifest).is_absolute() else Path(args.manifest)
        entries = _load_manifest(manifest_path)
    else:
        entries.append({
            "id": args.prompt_id,
            "text": args.text,
            "voice": None,
            "language_code": None,
            "speaking_rate": None,
            "filename": None,
        })

    dry_run = args.dry_run
    overwrite = args.overwrite
    do_ogg = args.ogg

    if do_ogg and not dry_run:
        try:
            result = subprocess.run(["wsl.exe", "ffmpeg", "-version"], capture_output=True, text=True, timeout=15)
            if result.returncode != 0:
                print("Warning: --ogg specified but ffmpeg not available in WSL. Will output WAV only.", file=sys.stderr)
                do_ogg = False
        except Exception:
            print("Warning: --ogg specified but ffmpeg not available in WSL. Will output WAV only.", file=sys.stderr)
            do_ogg = False

    if dry_run:
        print(f"\nDry run — no audio will be generated.\n")
        print(f"Project root: {project_root}")
        print(f"Output dir:   {output_dir}")
        print(f"Voice:        {args.voice}")
        print(f"Language:     {args.language_code}")
        print(f"Speaking rate: {args.rate}")
        print(f"OGG convert:  {do_ogg}")
        print(f"Overwrite:    {overwrite}")
        print(f"Entries:      {len(entries)}")
        print()

    client = None
    if not dry_run:
        try:
            client = texttospeech.TextToSpeechClient()
            print(f"TTS client ready.")
        except Exception as exc:
            exc_str = str(exc)
            print(f"Error creating TTS client: {exc_str}", file=sys.stderr)
            if "could not be found" in exc_str.lower() or "adc" in exc_str.lower() or "credentials" in exc_str.lower():
                print("\nTo fix: Install gcloud CLI, then run:", file=sys.stderr)
                print("  gcloud auth application-default login", file=sys.stderr)
            return 1

    total = len(entries)
    generated = 0
    skipped = 0
    errors = 0

    for i, entry in enumerate(entries):
        label = entry["id"]
        if dry_run:
            _synthesize(None, entry, output_dir, args.voice, args.language_code, args.rate,
                        overwrite, dry_run=True, do_ogg=do_ogg, project_root=project_root)
            continue

        try:
            result = _synthesize(client, entry, output_dir, args.voice, args.language_code, args.rate,
                                 overwrite, dry_run=False, do_ogg=do_ogg, project_root=project_root)
            if result is None:
                skipped += 1
            else:
                generated += 1
        except _SynthesizeError:
            errors += 1

    if not dry_run:
        print(f"\nSummary: {generated} generated, {skipped} skipped, {errors} errors of {total} entries.")
    else:
        print(f"\nDry run complete. Would process {total} entries.")
        print("Run without --dry-run to generate audio.")

    return 0 if errors == 0 else 1


if __name__ == "__main__":
    raise SystemExit(_run())
