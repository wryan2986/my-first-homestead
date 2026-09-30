# Santa Christmas Localization Tool

Generates localized Santa Christmas greetings using Google Cloud services.

## Overview

Each finished file contains:
1. The original CC0 "Ho, ho, ho!" laugh from Freesound
2. A short natural pause
3. Google Chirp 3 HD speech saying "Merry Christmas!" in the local language

**Google Cloud is used only during development.** No cloud libraries or credentials ship with the game.

## Original Laugh Source

- **Freesound ID:** 325180
- **Uploader:** bollenator
- **License:** Creative Commons Zero 1.0
- **Source file:** `_assets_archive/winter_audio_pond_polish_2026-06-19/sounds/325180__bollenator__santaclaus_hohoho.wav`
- **Laugh segment:** 4.3s – 6.7s (extracted via ffmpeg atrim)

## Prerequisites

- Google Cloud CLI installed
- Billing enabled on the Cloud project
- ADC configured: `gcloud auth application-default login`
- Required APIs enabled:
  ```
  gcloud services enable texttospeech.googleapis.com
  gcloud services enable translate.googleapis.com
  ```

## Setup

```powershell
python -m venv tools\voice_generation\santa\.venv
tools\voice_generation\santa\.venv\Scripts\activate
pip install -r tools\voice_generation\santa\requirements.txt
```

## Commands

```powershell
# Check environment, source file, and configuration
python tools\voice_generation\santa\generate_santa_localizations.py check

# List available Chirp 3 HD voices
python tools\voice_generation\santa\generate_santa_localizations.py list-voices

# Translate "Merry Christmas!" into all locales via Google Translation
python tools\voice_generation\santa\generate_santa_localizations.py translate --yes

# Generate TTS audio for each locale
python tools\voice_generation\santa\generate_santa_localizations.py generate --yes

# Build final OGG files (laugh + pause + greeting)
python tools\voice_generation\santa\generate_santa_localizations.py build

# Verify all OGG files
python tools\voice_generation\santa\generate_santa_localizations.py verify
```

## Adding a Locale

1. Add an entry to `santa_localizations.json` under `"entries"` with:
   - `"voice_name"`: the locale-specific Chirp 3 HD voice
   - `"translation_status"`: `"needs_google_translation"`
2. Run `translate` to draft the translation
3. Review and change `"translation_status"` to `"reviewed"` to protect from overwrite
4. Run `generate` and `build`

## Reviewing Translations

Google Translation outputs machine-generated text. Mark reviewed translations
as `"reviewed"` in the manifest so subsequent `translate` runs do not
overwrite them. Native-speaker review is recommended before shipping.

## Fallback Chain

When the player's locale doesn't match an exact Santa locale, the system falls
back:

1. Exact match (e.g., `es-MX`)
2. Configured fallback in the manifest (e.g., `es-US`)
3. Language prefix match (e.g., `es-*` → `es-US`)
4. Default `en-US`

## Output

Final files go to the locale voice-pack tree:

```
sounds/voice_over/locales/
├── en-US/
│   └── santa_full_greeting.ogg
├── es-US/
│   └── santa_full_greeting.ogg
├── fr-FR/
│   └── santa_full_greeting.ogg
├── de-DE/
│   └── santa_full_greeting.ogg
├── it-IT/
│   └── santa_full_greeting.ogg
└── pt-BR/
    └── santa_full_greeting.ogg
```

The Santa greeting is played through the **VoiceOver audio bus** and respects:
- Voice-over enabled/disabled setting
- Voice-over volume
- Master volume

It is **not** affected by the sound-effects toggle or sound-effects volume.

## Credential Safety

- Credentials are never committed to the repository
- ADC credentials live in `%APPDATA%\gcloud\`
- Only finished audio files and the minimal Godot lookup code ship with the game
- The `.gitignore` covers `work/`, `output/`, `.venv/`, `__pycache__/`

## Files

| Path | Purpose |
|---|---|
| `generate_santa_localizations.py` | CLI tool |
| `santa_localizations.json` | Manifest with translations and voice config |
| `source/` | Symlink/reference to original CC0 WAV |
| `work/` | Intermediate WAV files (gitignored) |
| `output/` | Intermediate OGG (gitignored) |
| `sounds/voice_over/locales/<locale>/` | Final Godot assets for each locale, including Santa greetings |
