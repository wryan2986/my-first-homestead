#!/usr/bin/env python3
"""Verify manually reviewed localized voice prompt translations."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


SUPPORTED_LOCALES = [
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

SCRIPT_PATTERNS = {
    "zh-CN": re.compile(r"[\u4e00-\u9fff]"),
    "ja": re.compile(r"[\u3040-\u30ff\u4e00-\u9fff]"),
    "ko": re.compile(r"[\uac00-\ud7af]"),
    "ar": re.compile(r"[\u0600-\u06ff]"),
    "hi": re.compile(r"[\u0900-\u097f]"),
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify manually reviewed voice prompt translations.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    args = parser.parse_args()

    root = Path(args.project_root).resolve()
    source_catalog_path = root / "sounds" / "voice_over" / "voice_lines.json"
    prompt_root = root / "localization" / "voice_prompts"
    manifest_path = prompt_root / "manual_review_manifest.json"

    errors: list[str] = []
    source_catalog = _load_json(source_catalog_path, errors)
    manifest = _load_json(manifest_path, errors)
    if not isinstance(source_catalog, dict) or not isinstance(manifest, dict):
        return _finish(errors)

    source_texts = _collect_source_texts(source_catalog, errors)
    reviewed = manifest.get("reviewed", {})
    if not isinstance(reviewed, dict):
        errors.append(f"{manifest_path}: reviewed must be an object")
        reviewed = {}

    for locale, file_name in SUPPORTED_LOCALES:
        translations = _load_json(prompt_root / file_name, errors)
        if not isinstance(translations, dict):
            continue
        locale_review = reviewed.get(locale, {})
        if not isinstance(locale_review, dict):
            errors.append(f"{manifest_path}: missing review entries for {locale}")
            locale_review = {}
        for source_text in source_texts:
            translated = str(translations.get(source_text, "")).strip()
            label = f"{locale}: {source_text}"
            if not translated:
                errors.append(f"{label}: missing translation")
                continue
            if translated == source_text:
                errors.append(f"{label}: translation is still English")
            if "??" in translated or translated.count("?") >= 2:
                errors.append(f"{label}: translation appears to contain replacement question marks")
            if _has_repeated_phrase_loop(translated):
                errors.append(f"{label}: translation appears to repeat a phrase")
            script_pattern = SCRIPT_PATTERNS.get(locale)
            if script_pattern != None and script_pattern.search(translated) == None:
                errors.append(f"{label}: translation does not contain the expected script")
            expected_digest = _digest(source_text, translated)
            review_entry = locale_review.get(source_text, {})
            if not isinstance(review_entry, dict):
                errors.append(f"{label}: missing manual review entry")
                continue
            if review_entry.get("digest") != expected_digest:
                errors.append(f"{label}: translation has changed since manual review")
            if review_entry.get("status") != "manually_verified":
                errors.append(f"{label}: review status is not manually_verified")

    return _finish(errors)


def _load_json(path: Path, errors: list[str]):
    if not path.exists():
        errors.append(f"missing file: {path}")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid JSON in {path}: {exc}")
        return None


def _collect_source_texts(catalog: dict, errors: list[str]) -> list[str]:
    lines = catalog.get("lines", [])
    if not isinstance(lines, list):
        errors.append("source voice catalog lines must be an array")
        return []
    texts: list[str] = []
    seen: set[str] = set()
    for index, line in enumerate(lines):
        if not isinstance(line, dict):
            errors.append(f"source voice catalog line {index} must be an object")
            continue
        text = str(line.get("text", "")).strip()
        if text and text not in seen:
            seen.add(text)
            texts.append(text)
    return texts


def _digest(source_text: str, translated_text: str) -> str:
    payload = json.dumps(
        {"source": source_text, "translation": translated_text},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _has_repeated_phrase_loop(text: str) -> bool:
    normalized = re.sub(r"[^\w\s]", " ", text.lower(), flags=re.UNICODE)
    words = [word for word in normalized.split() if word]
    if len(words) < 8:
        return False
    for size in range(2, 5):
        grams = [" ".join(words[index:index + size]) for index in range(len(words) - size + 1)]
        for gram in set(grams):
            if grams.count(gram) >= 3:
                return True
    return False


def _finish(errors: list[str]) -> int:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        return 1
    print("Voice prompt translations are manually verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
