#!/usr/bin/env python3
"""Generate bundled voice-over clips and locale-specific voice packs.

This is a local developer tool. It supports Google Cloud TTS as the primary
generation path, with command-template and OpenAI fallbacks for development.

The game never calls this tool at runtime.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

try:
    from google.cloud import texttospeech
    from google.cloud.texttospeech import AudioConfig, AudioEncoding, SynthesisInput, VoiceSelectionParams

    _GOOGLE_TTS_AVAILABLE = True
except ImportError:
    _GOOGLE_TTS_AVAILABLE = False

DEFAULT_CATALOG = Path("sounds") / "voice_over" / "voice_lines.json"
DEFAULT_TRANSLATION_ROOT = Path("localization") / "translations"
DEFAULT_VOICE_PROMPT_ROOT = Path("localization") / "voice_prompts"
OPENAI_SPEECH_URL = "https://api.openai.com/v1/audio/speech"
DEFAULT_GOOGLE_VOICE_FAMILY = "Aoede"
DEFAULT_SPEAKING_RATE = 0.92

GOOGLE_TTS_LOCALE_MAP = {
    "en": "en-US",
    "es": "es-US",
    "fr": "fr-FR",
    "pt-BR": "pt-BR",
    "de": "de-DE",
    "it": "it-IT",
    "zh-CN": "cmn-CN",
    "ja": "ja-JP",
    "ko": "ko-KR",
    "ar": "ar-XA",
    "hi": "hi-IN",
}

SUPPORTED_LOCALES = [
    ("en", "en.json"),
    ("es", "es.json"),
    ("fr", "fr.json"),
    ("pt-BR", "pt_br.json"),
    ("de", "de.json"),
    ("it", "it.json"),
    ("zh-CN", "zh_cn.json"),
    ("ja", "ja.json"),
    ("ko", "ko.json"),
    ("ar", "ar.json"),
    ("hi", "hi.json"),
]

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate Farm Chore Friends voice-over clips and locale packs."
    )
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    parser.add_argument("--catalog", default=str(DEFAULT_CATALOG), help="Source voice line JSON catalog.")
    parser.add_argument(
        "--translation-root",
        default=str(DEFAULT_TRANSLATION_ROOT),
        help="Root folder containing locale translation JSON files.",
    )
    parser.add_argument(
        "--voice-prompt-root",
        default=str(DEFAULT_VOICE_PROMPT_ROOT),
        help="Root folder containing voice-prompt translation JSON files.",
    )
    parser.add_argument("--locale", default="", help="Generate one locale pack, such as es or pt-BR.")
    parser.add_argument(
        "--all-locales",
        action="store_true",
        help="Generate locale packs for every shipped locale except English.",
    )
    parser.add_argument(
        "--provider",
        choices=["auto", "google", "command", "openai"],
        default="google",
        help="Speech backend to use for clip generation.",
    )
    parser.add_argument(
        "--command-json",
        default="",
        help="JSON array command template for local AI generation, with placeholders like {text} and {output}.",
    )
    parser.add_argument("--force", action="store_true", help="Regenerate files that already exist.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned files without writing anything.")
    parser.add_argument("--catalog-only", action="store_true", help="Write locale voice catalogs without generating audio files.")
    parser.add_argument("--only", action="append", default=[], help="Generate one key. Can be passed multiple times.")
    parser.add_argument("--model", default="", help="Override catalog model.")
    parser.add_argument("--voice", default="", help="Override catalog voice.")
    parser.add_argument("--speaking-rate", type=float, default=DEFAULT_SPEAKING_RATE, help="Google TTS speaking rate.")
    parser.add_argument("--response-format", default="", help="Override catalog response format, such as ogg or wav.")
    parser.add_argument("--pause", type=float, default=0.15, help="Pause between generated clips in seconds.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    catalog_path = _resolve_project_path(project_root, args.catalog)
    translation_root = _resolve_project_path(project_root, args.translation_root)
    voice_prompt_root = _resolve_project_path(project_root, args.voice_prompt_root)

    if not catalog_path.exists():
        print(f"Voice catalog not found: {catalog_path}", file=sys.stderr)
        return 1

    source_catalog = _load_json(catalog_path)
    if not isinstance(source_catalog, dict):
        print(f"Invalid source voice catalog: {catalog_path}", file=sys.stderr)
        return 1

    voice_config = source_catalog.get("voice", {})
    if not isinstance(voice_config, dict):
        voice_config = {}

    model = args.model or str(voice_config.get("model", "google")).strip() or "google"
    voice = args.voice or str(voice_config.get("voice", DEFAULT_GOOGLE_VOICE_FAMILY)).strip() or DEFAULT_GOOGLE_VOICE_FAMILY
    speaking_rate = float(voice_config.get("speaking_rate", args.speaking_rate))
    response_format = args.response_format or str(voice_config.get("response_format", "ogg")).strip() or "ogg"
    instructions = str(
        voice_config.get(
            "instructions",
            "Google Chirp 3-HD Aoede voice. Same calm adult woman voice. Calm, warm, friendly, clear preschool-teacher delivery for toddlers ages 2 to 5.",
        )
    ).strip()

    selected_keys = set(str(item).strip() for item in args.only if str(item).strip())
    target_locales = _resolve_target_locales(args, source_catalog)
    _verify_voice_prompt_translations(project_root, target_locales)
    backend = _resolve_backend(args.provider, model, args.command_json)
    command_json = args.command_json

    total_generated = 0
    total_skipped = 0
    for locale_code in target_locales:
        locale_catalog = _build_locale_catalog(
            source_catalog=source_catalog,
            locale_code=locale_code,
            translation_root=translation_root,
            voice_prompt_root=voice_prompt_root,
            response_format=response_format,
            source_voice=voice,
            source_model=model,
            source_instructions=instructions,
        )
        locale_output_path = _resolve_locale_catalog_path(project_root, locale_code)
        locale_generated, locale_skipped = _write_locale_pack(
            project_root=project_root,
            catalog=locale_catalog,
            catalog_path=locale_output_path,
            backend=backend,
            command_json=command_json,
            selected_keys=selected_keys,
            force=args.force,
            dry_run=args.dry_run,
            catalog_only=args.catalog_only,
            pause=args.pause,
        )
        total_generated += locale_generated
        total_skipped += locale_skipped

    print(
        "Done. Generated %d clips, skipped %d, locale packs: %d."
        % (total_generated, total_skipped, len(target_locales))
    )
    if args.dry_run:
        print("Dry run only; no files were written.")
    return 0


def _resolve_backend(provider: str, model: str, command_json: str) -> str:
    if provider != "auto":
        return provider
    if _GOOGLE_TTS_AVAILABLE:
        return "google"
    return "command" if _read_command_template(command_json) else "openai"


def _verify_voice_prompt_translations(project_root: Path, target_locales: list[str]) -> None:
    non_english_locales = [locale for locale in target_locales if locale and locale != "en"]
    if not non_english_locales:
        return
    verifier_path = project_root / "tools" / "verify_voice_prompt_translations.py"
    if not verifier_path.exists():
        raise RuntimeError(f"Missing voice prompt translation verifier: {verifier_path}")
    subprocess.run(
        [sys.executable, str(verifier_path), "--project-root", str(project_root)],
        cwd=project_root,
        check=True,
    )


def _resolve_target_locales(args: argparse.Namespace, source_catalog: dict) -> list[str]:
    if args.locale.strip():
        return [args.locale.strip()]
    if args.all_locales:
        return [locale_code for locale_code, _file_name in SUPPORTED_LOCALES if locale_code != "en"]
    source_locale = str(source_catalog.get("locale", "")).strip()
    return [source_locale if source_locale else "en"]


def _build_locale_catalog(
    source_catalog: dict,
    locale_code: str,
    translation_root: Path,
    voice_prompt_root: Path,
    response_format: str,
    source_voice: str,
    source_model: str,
    source_instructions: str,
) -> dict:
    translations = _load_locale_translations(translation_root, voice_prompt_root, locale_code)
    output_dir = _locale_output_dir(locale_code)
    lines = []
    untranslated_count = 0
    for line in source_catalog.get("lines", []):
        if not isinstance(line, dict):
            continue
        key = str(line.get("key", "")).strip()
        text = str(line.get("text", "")).strip()
        if not key or not text:
            continue
        localized_text = translations.get(text, text)
        if locale_code != "en" and localized_text.strip() == text.strip():
            untranslated_count += 1
        output_name = f"{key}.{response_format}"
        if output_dir:
            output_path = f"res://sounds/voice_over/{output_dir}/{output_name}"
        else:
            output_path = f"res://sounds/voice_over/{output_name}"
        lines.append(
            {
                "key": key,
                "text": localized_text,
                "path": output_path,
                "notes": str(line.get("notes", "")).strip(),
            }
        )

    catalog = {
        "version": int(source_catalog.get("version", 1)),
        "locale": locale_code,
        "voice": {
            "model": source_model,
            "voice": source_voice,
            "speaking_rate": float(source_catalog.get("voice", {}).get("speaking_rate", DEFAULT_SPEAKING_RATE)),
            "response_format": response_format,
            "instructions": source_instructions,
            "google_tts_locale": _google_tts_locale(locale_code),
            "google_tts_voice": _google_voice_name(locale_code, source_voice),
        },
        "lines": lines,
    }
    aliases = source_catalog.get("aliases", {})
    if isinstance(aliases, dict) and aliases:
        catalog["aliases"] = aliases
    if locale_code != "en" and lines and untranslated_count == len(lines):
        raise RuntimeError(
            f"{locale_code} locale text is still English. Rebuild localization catalogs before generating voice."
        )
    return catalog


def _write_locale_pack(
    project_root: Path,
    catalog: dict,
    catalog_path: Path,
    backend: str,
    command_json: str,
    selected_keys: set[str],
    force: bool,
    dry_run: bool,
    catalog_only: bool,
    pause: float,
) -> tuple[int, int]:
    output_dir = catalog_path.parent
    generated = 0
    skipped = 0

    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)
        catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    else:
        print(f"write catalog  {catalog_path}")

    if catalog_only:
        print(f"catalog only   {catalog_path}")
        return generated, skipped

    for line in catalog.get("lines", []):
        if not isinstance(line, dict):
            continue
        key = str(line.get("key", "")).strip()
        text = str(line.get("text", "")).strip()
        output_path = _resolve_project_path(project_root, str(line.get("path", "")).strip())
        if not key or not text:
            continue
        if selected_keys and key not in selected_keys:
            continue
        if output_path.exists() and not force:
            skipped += 1
            print(f"skip existing  {key} -> {output_path}")
            continue
        if dry_run:
            print(f"would generate {key} -> {output_path}")
            continue
        output_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"generate       {key} -> {output_path}")
        _generate_clip(
            backend=backend,
            command_json=command_json,
            key=key,
            text=text,
            output_path=output_path,
            voice=str(catalog.get("voice", {}).get("voice", DEFAULT_GOOGLE_VOICE_FAMILY)),
            instructions=str(catalog.get("voice", {}).get("instructions", "")),
            locale=str(catalog.get("locale", "")),
            model=str(catalog.get("voice", {}).get("model", "google")),
            speaking_rate=float(catalog.get("voice", {}).get("speaking_rate", DEFAULT_SPEAKING_RATE)),
            response_format=str(catalog.get("voice", {}).get("response_format", "ogg")),
        )
        generated += 1
        if pause > 0.0:
            time.sleep(pause)

    return generated, skipped


def _generate_clip(
    backend: str,
    command_json: str,
    key: str,
    text: str,
    output_path: Path,
    voice: str,
    instructions: str,
    locale: str,
    model: str,
    speaking_rate: float,
    response_format: str,
) -> None:
    if backend == "google":
        client = _get_google_tts_client()
        if client is None:
            raise RuntimeError("Google TTS client is not available. Install google-cloud-texttospeech and configure ADC.")
        google_locale = _google_tts_locale(locale)
        google_voice = _google_voice_name(locale, voice)
        input_config = SynthesisInput(text=text)
        voice_config = VoiceSelectionParams(language_code=google_locale, name=google_voice)
        audio_config = AudioConfig(
            audio_encoding=AudioEncoding.LINEAR16,
            speaking_rate=speaking_rate,
        )
        response = client.synthesize_speech(
            request={"input": input_config, "voice": voice_config, "audio_config": audio_config}
        )
        temp_path = output_path.with_suffix(output_path.suffix + ".tmp")
        temp_path.write_bytes(response.audio_content)
        temp_path.replace(output_path)
        return

    if backend == "openai":
        api_key = os.environ.get("OPENAI_API_KEY", "").strip()
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY is not set.")
        audio = _request_openai_speech(
            api_key=api_key,
            model=model,
            voice=voice,
            text=text,
            instructions=instructions,
            response_format=response_format,
        )
        temp_path = output_path.with_suffix(output_path.suffix + ".tmp")
        temp_path.write_bytes(audio)
        temp_path.replace(output_path)
        return

    command = _read_command_template(command_json, backend)
    if not command:
        raise RuntimeError(
            "No local TTS command template configured. Set VOICE_OVER_TTS_COMMAND_JSON "
            "or pass --command-json with a JSON command array."
        )
    rendered = [_render_command_part(part, key=key, text=text, output_path=output_path, voice=voice, instructions=instructions, locale=locale, model=model, response_format=response_format) for part in command]
    subprocess.run(rendered, check=True)
    if not output_path.exists():
        raise RuntimeError(f"Local TTS command completed without creating {output_path}")


def _read_command_template(command_json: str, backend: str | None = None) -> list[str]:
    env_name = "VOICE_OVER_TTS_COMMAND_JSON"
    raw = command_json.strip()
    if not raw:
        raw = os.environ.get("VOICE_OVER_TTS_COMMAND_JSON", "").strip()
    if not raw:
        return []
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{env_name} must be a JSON array: {exc}") from exc
    if not isinstance(value, list) or not value:
        raise RuntimeError(f"{env_name} must be a non-empty JSON array.")
    return [str(part) for part in value]


def _get_google_tts_client():
    if not _GOOGLE_TTS_AVAILABLE:
        return None
    try:
        return texttospeech.TextToSpeechClient()
    except Exception:
        return None


def _render_command_part(
    part: str,
    key: str,
    text: str,
    output_path: Path,
    voice: str,
    instructions: str,
    locale: str,
    model: str,
    response_format: str,
) -> str:
    replacements = {
        "key": key,
        "text": text,
        "output": str(output_path),
        "voice": voice,
        "instructions": instructions,
        "locale": locale,
        "model": model,
        "response_format": response_format,
    }
    rendered = part
    for placeholder, value in replacements.items():
        rendered = rendered.replace("{" + placeholder + "}", value)
    return rendered


def _load_locale_translations(translation_root: Path, voice_prompt_root: Path, locale_code: str) -> dict[str, str]:
    translations: dict[str, str] = {}
    for root in (translation_root, voice_prompt_root):
        translations.update(_load_translation_file(root, locale_code))
    return translations


def _load_translation_file(root: Path, locale_code: str) -> dict[str, str]:
    file_name = dict(SUPPORTED_LOCALES).get(locale_code)
    if file_name is None:
        for supported_code, supported_name in SUPPORTED_LOCALES:
            if supported_code.lower() == locale_code.lower():
                file_name = supported_name
                break
    if file_name is None:
        return {}
    translation_path = root / file_name
    if not translation_path.exists():
        return {}
    data = _load_json(translation_path)
    if not isinstance(data, dict):
        return {}
    return {str(key): str(value) for key, value in data.items()}


def _request_openai_speech(
    api_key: str,
    model: str,
    voice: str,
    text: str,
    instructions: str,
    response_format: str,
) -> bytes:
    payload = {
        "model": model,
        "voice": voice,
        "input": text,
        "instructions": instructions,
        "response_format": response_format,
    }
    request = urllib.request.Request(
        OPENAI_SPEECH_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenAI speech request failed: HTTP {exc.code}: {details}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"OpenAI speech request failed: {exc}") from exc


def _locale_output_dir(locale_code: str) -> str:
    if not locale_code or locale_code == "en":
        return ""
    return f"locales/{locale_code}"


def _google_tts_locale(locale_code: str) -> str:
    return GOOGLE_TTS_LOCALE_MAP.get(locale_code, "en-US")


def _google_voice_name(locale_code: str, voice_family: str) -> str:
    return f"{_google_tts_locale(locale_code)}-Chirp3-HD-{voice_family}"
def _resolve_locale_catalog_path(project_root: Path, locale_code: str) -> Path:
    if not locale_code or locale_code == "en":
        return _resolve_project_path(project_root, DEFAULT_CATALOG)
    return _resolve_project_path(project_root, Path("sounds") / "voice_over" / _locale_output_dir(locale_code) / "voice_lines.json")


def _resolve_project_path(project_root: Path, path_text: str | Path) -> Path:
    path_str = str(path_text)
    if path_str.startswith("res://"):
        return project_root / path_str.replace("res://", "", 1)
    path = Path(path_str)
    if path.is_absolute():
        return path
    return project_root / path


def _load_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON in {path}: {exc}") from exc


if __name__ == "__main__":
    raise SystemExit(main())
