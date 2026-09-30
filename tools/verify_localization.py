#!/usr/bin/env python3
"""Validate the localization catalogs and locale-specific voice pack manifests."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


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
    parser = argparse.ArgumentParser(description="Verify localization catalogs.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    translation_root = project_root / "localization" / "translations"
    voice_prompt_root = project_root / "localization" / "voice_prompts"
    voice_root = project_root / "sounds" / "voice_over" / "locales"
    shared_voice_catalog_path = project_root / "sounds" / "voice_over" / "voice_lines.json"

    errors: list[str] = []
    warnings: list[str] = []

    base_translation = _load_json(translation_root / "en.json", errors, "base translation")
    if not isinstance(base_translation, dict) or not base_translation:
        errors.append("base translation file is missing or empty")
        base_translation = {}

    base_keys = set(base_translation.keys())
    shared_voice_catalog = _load_json(shared_voice_catalog_path, errors, "shared voice catalog")
    shared_voice_keys = _collect_voice_keys(shared_voice_catalog, errors, "shared voice catalog")
    shared_voice_text_by_key = _collect_voice_text_map(shared_voice_catalog, errors, "shared voice catalog")
    shared_voice_texts = sorted({text for text in shared_voice_text_by_key.values() if text})

    for locale_code, file_name in SUPPORTED_LOCALES:
        translation_path = translation_root / file_name
        voice_prompt_path = voice_prompt_root / file_name
        catalog_path = voice_root / locale_code / "voice_lines.json"

        translation_data = _load_json(translation_path, errors, f"{locale_code} translation")
        voice_prompt_data = _load_json(voice_prompt_path, errors, f"{locale_code} voice prompt translation")
        if isinstance(translation_data, dict):
            missing_keys = sorted(base_keys - set(translation_data.keys()))
            if missing_keys:
                errors.append(
                    f"{locale_code} translation is missing {len(missing_keys)} key(s): "
                    + ", ".join(missing_keys[:12])
                    + (" ..." if len(missing_keys) > 12 else "")
                )
        if isinstance(voice_prompt_data, dict):
            missing_voice_texts = sorted(set(shared_voice_texts) - set(voice_prompt_data.keys()))
            if missing_voice_texts:
                errors.append(
                    f"{locale_code} voice prompt translation is missing {len(missing_voice_texts)} key(s): "
                    + ", ".join(missing_voice_texts[:8])
                    + (" ..." if len(missing_voice_texts) > 8 else "")
                )

        voice_catalog = _load_json(catalog_path, errors, f"{locale_code} voice catalog")
        if not isinstance(voice_catalog, dict):
            errors.append(f"{locale_code} voice catalog is missing or invalid")
            continue

        lines = voice_catalog.get("lines", [])
        if not isinstance(lines, list) or not lines:
            warnings.append(f"{locale_code} voice catalog has no line entries")
            continue

        locale_keys = _collect_voice_keys(voice_catalog, errors, f"{locale_code} voice catalog")
        if shared_voice_keys and locale_keys and locale_keys != shared_voice_keys:
            missing_locale_keys = sorted(shared_voice_keys - locale_keys)
            extra_locale_keys = sorted(locale_keys - shared_voice_keys)
            if missing_locale_keys:
                errors.append(
                    f"{locale_code} voice catalog is missing {len(missing_locale_keys)} shared key(s): "
                    + ", ".join(missing_locale_keys[:12])
                    + (" ..." if len(missing_locale_keys) > 12 else "")
                )
            if extra_locale_keys:
                errors.append(
                    f"{locale_code} voice catalog has {len(extra_locale_keys)} unexpected key(s): "
                    + ", ".join(extra_locale_keys[:12])
                    + (" ..." if len(extra_locale_keys) > 12 else "")
                )

        translation_lookup: dict[str, str] = {}
        if isinstance(translation_data, dict):
            translation_lookup.update({str(key): str(value) for key, value in translation_data.items()})
        if isinstance(voice_prompt_data, dict):
            translation_lookup.update({str(key): str(value) for key, value in voice_prompt_data.items()})

        untranslated_count = 0
        if isinstance(lines, list):
            for line in lines:
                if not isinstance(line, dict):
                    continue
                key = str(line.get("key", "")).strip()
                text = str(line.get("text", "")).strip()
                source_text = str(shared_voice_text_by_key.get(key, "")).strip()
                translated_text = str(translation_lookup.get(source_text, "")).strip()
                if key and text and source_text and text == source_text and translated_text == source_text:
                    untranslated_count += 1
                if locale_code != "en" and key and text and source_text and translated_text and text != translated_text:
                    errors.append(
                        f"{locale_code} voice catalog text for {key} does not match the reviewed translation source."
                    )
            if locale_code != "en" and lines and untranslated_count == len(lines):
                errors.append(f"{locale_code} voice catalog text is still English; regenerate the localized pack.")

        for line in lines:
            if not isinstance(line, dict):
                continue
            path_text = str(line.get("path", "")).strip()
            if not path_text.startswith("res://sounds/voice_over/locales/"):
                continue
            output_path = project_root / path_text.replace("res://", "", 1)
            if not output_path.exists():
                warnings.append(f"{locale_code}: missing localized voice file {path_text}")

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    if errors:
        return 1
    print("Localization catalogs look good.")
    return 0


def _load_json(path: Path, errors: list[str], label: str):
    if not path.exists():
        errors.append(f"missing {label}: {path}")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid {label}: {path} ({exc})")
        return None


def _collect_voice_keys(catalog, errors: list[str], label: str) -> set[str]:
    if not isinstance(catalog, dict):
        return set()
    lines = catalog.get("lines", [])
    if not isinstance(lines, list):
        errors.append(f"{label} lines must be an array")
        return set()
    keys: set[str] = set()
    for index, line in enumerate(lines):
        if not isinstance(line, dict):
            errors.append(f"{label} lines[{index}] must be an object")
            continue
        key = str(line.get("key", "")).strip()
        if not key:
            errors.append(f"{label} lines[{index}].key is required")
            continue
        keys.add(key)
    return keys


def _collect_voice_text_map(catalog, errors: list[str], label: str) -> dict[str, str]:
    if not isinstance(catalog, dict):
        return {}
    lines = catalog.get("lines", [])
    if not isinstance(lines, list):
        errors.append(f"{label} lines must be an array")
        return {}
    mapping: dict[str, str] = {}
    for index, line in enumerate(lines):
        if not isinstance(line, dict):
            continue
        key = str(line.get("key", "")).strip()
        text = str(line.get("text", "")).strip()
        if key:
            mapping[key] = text
    return mapping


if __name__ == "__main__":
    raise SystemExit(main())
