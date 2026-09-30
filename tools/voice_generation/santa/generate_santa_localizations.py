#! /usr/bin/env python3
"""Generate localized Santa Christmas greetings using Google Cloud services."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

try:
    from google.cloud import texttospeech
    from google.cloud.texttospeech import AudioConfig, AudioEncoding, SsmlVoiceGender, SynthesisInput, VoiceSelectionParams
except ImportError:
    print("Missing google-cloud-texttospeech. pip install -r requirements.txt", file=sys.stderr)
    sys.exit(1)

try:
    from google.cloud import translate
except ImportError:
    print("Missing google-cloud-translate. pip install -r requirements.txt", file=sys.stderr)
    sys.exit(1)

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
MANIFEST_PATH = Path(__file__).resolve().parent / "santa_localizations.json"
WORK_DIR = Path(__file__).resolve().parent / "work"
OUTPUT_DIR = Path(__file__).resolve().parent / "output"
SANTA_VOICE_DIR = PROJECT_ROOT / "sounds" / "voice_over" / "santa"
SAMPLE_RATE = 24000
TTS_LOCALE = "en-US"

SOURCE_FALLBACK = "en-US"
LOCALE_FALLBACKS = {
    "es-MX": "es-US", "es-AR": "es-US", "es-ES": "es-US",
    "fr-CA": "fr-FR", "fr-BE": "fr-FR",
    "de-AT": "de-DE", "de-CH": "de-DE",
    "it-CH": "it-IT",
    "pt-PT": "pt-BR",
    "en-GB": "en-US", "en-AU": "en-US",
}


def _load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        print(f"Error: Manifest not found: {MANIFEST_PATH}", file=sys.stderr)
        sys.exit(1)
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8-sig"))


def _save_manifest(manifest: dict) -> None:
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _resolve_locale(requested: str, entries: dict) -> str:
    if requested in entries:
        return requested
    if requested in LOCALE_FALLBACKS:
        fb = LOCALE_FALLBACKS[requested]
        if fb in entries:
            return fb
    lang = requested.split("-")[0]
    for code in entries:
        if code.startswith(lang):
            return code
    return SOURCE_FALLBACK


def _wsl_path(p: Path) -> str:
    drive = p.drive[0].lower()
    rest = str(p.relative_to(p.anchor)).replace("\\", "/")
    return f"/mnt/{drive}/{rest}"


def _find_gcloud() -> str | None:
    candidates = [
        "gcloud.cmd", "gcloud",
        str(Path(Path.home() / "AppData" / "Local" / "Google" / "Cloud SDK" / "google-cloud-sdk" / "bin" / "gcloud.cmd")),
    ]
    for c in candidates:
        try:
            r = subprocess.run([c, "--version"], capture_output=True, text=True, timeout=10)
            if r.returncode == 0:
                return c
        except Exception:
            continue
    return None


# ── check ──────────────────────────────────────────────────────────────────


def cmd_check(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    print("Santa Localization Tool — Check")
    print("=" * 50)

    gcloud = _find_gcloud()
    if gcloud:
        print(f"\ngcloud:     found")
        r = subprocess.run([gcloud, "config", "get-value", "project"], capture_output=True, text=True, timeout=15)
        print(f"Project:    {r.stdout.strip() or '(not set)'}")
        r = subprocess.run([gcloud, "auth", "application-default", "print-access-token"],
                           capture_output=True, text=True, timeout=15)
        print(f"ADC:        {'OK' if r.returncode == 0 else 'NOT CONFIGURED'}")
        for api in ["texttospeech.googleapis.com", "translate.googleapis.com"]:
            r = subprocess.run([gcloud, "services", "list", "--enabled", f"--filter=name:{api}", "--format=value(name)"],
                               capture_output=True, text=True, timeout=15)
            print(f"{'TTS API' if 'tts' in api else 'Trans API'}: {'Enabled' if api in r.stdout else 'DISABLED'}")
    else:
        print("\ngcloud:     NOT FOUND — install Google Cloud SDK")

    source_path = PROJECT_ROOT / manifest["source_audio"]
    print(f"\nSource WAV:  {source_path}")
    print(f"  Exists:    {source_path.exists()}")
    if source_path.exists():
        r = subprocess.run(["wsl.exe", "ffprobe", "-v", "error", "-show_entries", "format=duration",
                            "-of", "default=noprint_wrappers=1", _wsl_path(source_path)],
                           capture_output=True, text=True, timeout=15)
        print(f"  Duration:  {r.stdout.strip() or 'unknown'}s")

    print(f"\nLaugh trim:  {manifest['laugh_start_seconds']}s – {manifest['laugh_end_seconds']}s")
    print(f"Pause:       {manifest['pause_milliseconds']}ms")
    print(f"Default:     {manifest['default_locale']}")
    print(f"Voice:       {manifest['voice_name']}")
    print(f"Rate:        {manifest['speaking_rate']}")

    print(f"\nLocales ({len(manifest['entries'])}):")
    for code, entry in manifest["entries"].items():
        status = entry["translation_status"]
        has_text = bool(entry.get("text"))
        print(f"  {code:<8s} {status:<25s} text={'yes' if has_text else 'no'}  voice={entry['voice_name']}")

    print(f"\nffprobe:     {'available' if subprocess.run(['wsl.exe','which','ffprobe'],capture_output=True).returncode==0 else 'check via WSL'}")
    print(f"ffmpeg:      {'available' if subprocess.run(['wsl.exe','which','ffmpeg'],capture_output=True).returncode==0 else 'check via WSL'}")

    final_dir = SANTA_VOICE_DIR
    print(f"\nFinal dir:   {final_dir}")
    print(f"Existing:    {len(list(final_dir.rglob('*.ogg'))) if final_dir.exists() else 0} files")
    print("\nCheck complete.")
    return 0


# ── translate ──────────────────────────────────────────────────────────────


def cmd_translate(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    entries = manifest["entries"]
    target_locales = [c for c, e in entries.items() if e.get("translation_status") == "needs_google_translation"]

    if not target_locales:
        print("No locales need translation.")
        return 0

    lang_map = {c: c.split("-")[0] for c in target_locales}
    client = translate.TranslationServiceClient()
    parent = f"projects/{_get_project_id()}/locations/global"

    source_text = entries[SOURCE_FALLBACK]["text"]
    total_req = len(target_locales)

    if not args.yes and not args.dry_run:
        print(f"Translate '{source_text}' into {total_req} locales: {', '.join(target_locales)}")
        try:
            resp = input("Continue? [y/N] ").strip().lower()
            if resp != "y":
                print("Cancelled.")
                return 0
        except EOFError:
            print("Non-interactive; pass --yes.")
            return 1

    if args.dry_run:
        print(f"\nDry run — would translate {total_req} locales:")
        for code in target_locales:
            print(f"  {code}  ({lang_map[code]})")
        return 0

    for code in target_locales:
        lang = lang_map[code]
        try:
            response = client.translate_text(
                request={
                    "parent": parent,
                    "contents": [source_text],
                    "target_language_code": lang,
                    "source_language_code": "en",
                }
            )
            translation = response.translations[0].translated_text
            entries[code]["text"] = translation
            entries[code]["translation_status"] = "google_draft"
            print(f"  {code:<8s} {translation}")
        except Exception as exc:
            print(f"  {code:<8s} ERROR: {exc}", file=sys.stderr)

    _save_manifest(manifest)
    print(f"\nManifest updated with translations. Review and mark as 'reviewed' to protect from overwrite.")
    return 0


def _get_project_id() -> str:
    gcloud = _find_gcloud()
    if gcloud:
        r = subprocess.run([gcloud, "config", "get-value", "project"], capture_output=True, text=True, timeout=15)
        pid = r.stdout.strip()
        if pid:
            return pid
    return ""


# ── list-voices ────────────────────────────────────────────────────────────


def cmd_list_voices(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    client = texttospeech.TextToSpeechClient()
    locales = list(manifest["entries"].keys()) if not args.locale else [args.locale]
    for loc in locales:
        print(f"\n=== {loc} ===")
        resp = client.list_voices(language_code=loc)
        for v in resp.voices:
            if "Chirp3-HD" in v.name:
                gender = SsmlVoiceGender(v.ssml_gender).name if v.ssml_gender else "UNKNOWN"
                print(f"  {v.name:<48s} {gender}")
    return 0


# ── generate ───────────────────────────────────────────────────────────────


def cmd_generate(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    entries = manifest["entries"]

    if not args.yes and not args.dry_run:
        needing_tts = [c for c, e in entries.items() if e.get("text") and e.get("voice_name")]
        print(f"Generate TTS for {len(needing_tts)} locales.")
        try:
            resp = input("Continue? [y/N] ").strip().lower()
            if resp != "y":
                print("Cancelled.")
                return 0
        except EOFError:
            print("Non-interactive; pass --yes.")
            return 1

    work_dir = WORK_DIR
    work_dir.mkdir(parents=True, exist_ok=True)
    client = texttospeech.TextToSpeechClient()

    for code, entry in entries.items():
        text = entry.get("text", "")
        voice_name = entry.get("voice_name", "")
        if not text or not voice_name:
            print(f"  {code:<8s} SKIP — no text or voice configured")
            continue

        wav_path = work_dir / f"santa_greeting_{code}.wav"
        if wav_path.exists() and not args.overwrite:
            print(f"  {code:<8s} SKIP (exists)")
            continue

        if args.dry_run:
            print(f"  {code:<8s} Would generate: {wav_path.name} (text={text!r}, voice={voice_name})")
            continue

        try:
            # Lower pitch for Santa-like deep jolly voice
            pitch = manifest.get("pitch", "-2st")
            ssml = f"<speak><prosody rate='{manifest['speaking_rate']}' pitch='{pitch}'>{_escape_xml(text)}</prosody></speak>"
            resp = client.synthesize_speech(request={
                "input": SynthesisInput(ssml=ssml),
                "voice": VoiceSelectionParams(language_code=entry.get("google_tts_locale", code), name=voice_name),
                "audio_config": AudioConfig(audio_encoding=AudioEncoding.LINEAR16, sample_rate_hertz=SAMPLE_RATE),
            })
            wav_path.write_bytes(resp.audio_content)
            print(f"  {code:<8s} Generated: {wav_path}")
        except Exception as exc:
            print(f"  {code:<8s} ERROR: {exc}", file=sys.stderr)

    return 0


def _escape_xml(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;").replace("'", "&apos;")


def _sh_quote(value: str) -> str:
    escaped = value.replace("'", "'\\''")
    return f"'{escaped}'"


# ── build ──────────────────────────────────────────────────────────────────


def cmd_build(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    entries = manifest["entries"]
    source_path = PROJECT_ROOT / manifest["source_audio"]
    laugh_start = manifest["laugh_start_seconds"]
    laugh_end = manifest["laugh_end_seconds"]
    pause_ms = manifest["pause_milliseconds"]

    if not source_path.exists():
        print(f"Error: Source not found: {source_path}", file=sys.stderr)
        return 1

    final_dir = SANTA_VOICE_DIR
    output_dir = OUTPUT_DIR
    output_dir.mkdir(parents=True, exist_ok=True)

    for code, entry in entries.items():
        text = entry.get("text", "")
        if not text:
            print(f"  {code:<8s} SKIP — no text")
            continue

        greeting_wav = WORK_DIR / f"santa_greeting_{code}.wav"
        if not greeting_wav.exists():
            print(f"  {code:<8s} SKIP — greeting not generated yet (run generate first)")
            continue

        locale_dir = final_dir / code
        locale_dir.mkdir(parents=True, exist_ok=True)
        output_ogg = locale_dir / "santa_full_greeting.ogg"
        intermediate_ogg = output_dir / f"santa_full_greeting_{code}.ogg"

        if output_ogg.exists() and not args.overwrite:
            print(f"  {code:<8s} SKIP (exists): {output_ogg}")
            continue

        pause_seconds = pause_ms / 1000.0
        # Build using WSL ffmpeg - write script to WSL /tmp to avoid Windows path spacing issues
        # Trim leading silence from greeting, add pause delay, then concat with laugh
        filter_str = (
            f"[0:a]atrim=start={laugh_start}:end={laugh_end},asetpts=PTS-STARTPTS[a];"
            f"[1:a]silenceremove=start_periods=1:start_threshold=0.02:start_silence=0.001,"
            f"adelay={int(pause_ms)}|{int(pause_ms)},asetpts=PTS-STARTPTS[b];"
            f"[a][b]concat=n=2:v=0:a=1,"
            f"aformat=sample_rates=24000:channel_layouts=mono,"
            f"loudnorm=I=-16:LRA=7:TP=-1.5"
        )
        wsl_filter = filter_str  # plain brackets, base64 avoids shell escaping
        src_wsl = _wsl_path(source_path)
        greet_wsl = _wsl_path(greeting_wav)
        out_wsl = _wsl_path(intermediate_ogg)
        script_content = (
            f"#!/bin/bash\nset -euo pipefail\n"
            f"ffmpeg -y -i '{src_wsl}' -i '{greet_wsl}' "
            f"-filter_complex '{wsl_filter}' "
            f"-ac 1 -c:a libvorbis -q:a 4 '{out_wsl}'\n"
        )
        # Base64-encode the script to avoid all shell escaping issues
        import base64
        b64 = base64.b64encode(script_content.encode()).decode()
        cmd = ["wsl.exe", "bash", "-c",
               f"echo {b64} | base64 -d > /tmp/build_santa_{code}.sh && chmod +x /tmp/build_santa_{code}.sh && /tmp/build_santa_{code}.sh"]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            if result.returncode != 0:
                print(f"  {code:<8s} ffmpeg error: {result.stderr[-300:]}", file=sys.stderr)
                continue
        except Exception as exc:
            print(f"  {code:<8s} ffmpeg error: {exc}", file=sys.stderr)
            continue

        if intermediate_ogg.exists():
            shutil.copy2(intermediate_ogg, output_ogg)
            print(f"  {code:<8s} Built: {output_ogg} ({intermediate_ogg.stat().st_size} bytes)")
        else:
            print(f"  {code:<8s} ffmpeg produced no output", file=sys.stderr)

    print("\nBuild complete. Godot-ready files in:", final_dir)
    return 0


# ── verify ─────────────────────────────────────────────────────────────────


def cmd_verify(args: argparse.Namespace) -> int:
    manifest = _load_manifest()
    entries = manifest["entries"]
    ok = 0
    fail = 0

    for code in entries:
        ogg_path = SANTA_VOICE_DIR / code / "santa_full_greeting.ogg"
        if not ogg_path.exists():
            print(f"  {code:<8s} MISSING — {ogg_path}")
            fail += 1
            continue
        try:
            r = subprocess.run(["wsl.exe", "ffprobe", "-v", "error",
                                "-show_entries", "stream=codec_name,sample_rate,channels,duration",
                                "-of", "csv=p=0", _wsl_path(ogg_path)],
                               capture_output=True, text=True, timeout=15)
            parts = r.stdout.strip().split(",")
            codec, sr, ch, dur = parts[0], parts[1], parts[2], parts[3]
            size = ogg_path.stat().st_size
            print(f"  {code:<8s} OK — {codec}, {sr}Hz, {ch}ch, {dur}s, {size} bytes")
            ok += 1
        except Exception as exc:
            print(f"  {code:<8s} ERROR: {exc}", file=sys.stderr)
            fail += 1

    if ok == 0 and fail == 0:
        print("No files found. Run 'build' first.")
        return 1
    print(f"\n{ok} ok, {fail} failed")
    return 0 if fail == 0 else 1


# ── main ───────────────────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate localized Santa Christmas greetings.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_check = sub.add_parser("check")
    p_check.set_defaults(func=cmd_check)

    p_trans = sub.add_parser("translate")
    p_trans.add_argument("--dry-run", action="store_true")
    p_trans.add_argument("--yes", action="store_true")
    p_trans.set_defaults(func=cmd_translate)

    p_list = sub.add_parser("list-voices")
    p_list.add_argument("--locale", default="", help="Specific locale to list")
    p_list.set_defaults(func=cmd_list_voices)

    p_gen = sub.add_parser("generate")
    p_gen.add_argument("--dry-run", action="store_true")
    p_gen.add_argument("--yes", action="store_true")
    p_gen.add_argument("--overwrite", action="store_true")
    p_gen.set_defaults(func=cmd_generate)

    p_build = sub.add_parser("build")
    p_build.add_argument("--overwrite", action="store_true")
    p_build.set_defaults(func=cmd_build)

    p_verify = sub.add_parser("verify")
    p_verify.set_defaults(func=cmd_verify)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
