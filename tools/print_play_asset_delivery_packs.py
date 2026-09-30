#!/usr/bin/env python3
"""Print the intended Play Asset Delivery pack names for locale voice packs."""

from __future__ import annotations

import argparse
from pathlib import Path


BASE_SHARED_FILES = (
    "res://sounds/voice_over/*.ogg",
    "res://sounds/voice_over/voice_lines.json",
    "res://sounds/voice_over/locales/en-US/santa_full_greeting.ogg",
)

SHIPPED_VOICE_LOCALES = (
    "es",
    "fr",
    "pt-BR",
    "de",
    "it",
    "zh-CN",
    "ja",
    "ko",
    "ar",
    "hi",
)

SANTA_REGIONAL_LOCALES = (
    "en-US",
    "es-US",
    "fr-FR",
    "de-DE",
    "it-IT",
    "pt-BR",
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Print Play Asset Delivery pack names.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    locale_root = project_root / "sounds" / "voice_over" / "locales"
    if not locale_root.exists():
        print(f"Locale voice folder not found: {locale_root}")
        return 1

    print("Base bundle:")
    for entry in BASE_SHARED_FILES:
        print(f"  - {entry}")

    print()
    print("Play Asset Delivery packs:")
    for locale_code in SHIPPED_VOICE_LOCALES:
        print(f"  - voice_{locale_code.lower().replace('-', '_')} -> res://sounds/voice_over/locales/{locale_code}/")

    print()
    print("Regional Santa packs:")
    for locale_code in SANTA_REGIONAL_LOCALES:
        print(f"  - santa_{locale_code.lower().replace('-', '_')} -> res://sounds/voice_over/locales/{locale_code}/")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
