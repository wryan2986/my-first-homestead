# Voice-Over System Decision

## Decision

Use bundled recorded voice-over clips as the primary voice path. The first voice pack has been generated with Google Cloud Chirp 3 HD during development, and the same files can later be replaced by natural human recordings without code or scene rewiring.

The project now keeps a Google-first AI generation pipeline in `tools/generate_voice_over.py`. That script can build the shared English pack or per-locale packs from the translation catalogs, so the game ships only generated audio and never performs runtime TTS generation.

Runtime cloud voice generation is intentionally out of scope for the toddler app.

## Why This Fits The Game

- Voice quality is consistent across Android devices because the app plays the same bundled clips everywhere.
- The app does not need internet permission, an API key, or runtime OpenAI calls.
- Store/privacy review stays simpler for a toddler game.
- A calm female narrator can be kept consistent by using one fixed Google AI voice/instruction or one human speaker.
- Human recordings are easy to add later because prompt keys, filenames, and exact line text are cataloged.

## Alternatives Considered

- Platform OS TTS only: simplest technically, but voice quality and tone vary by device and can sound robotic.
- Runtime OpenAI TTS: highest flexibility, but it would require network access, runtime credentials, latency handling, and more child-privacy/compliance review. It can still be used as a developer-only fallback for generating clips offline.
- Human-only recording first: best naturalness, but slower to iterate while the text is still changing.

## Implemented Architecture

- `VoiceOverManager.gd` prefers localized recorded clips first, then shared clips from `res://sounds/voice_over/voice_lines.json`.
- If a clip is missing, Godot platform TTS remains a fallback.
- `FarmState.get_chore_completion_feedback()` returns both visible text and matching voice key.
- The current generated pack uses OGG files under `res://sounds/voice_over/`, with paths cataloged in `voice_lines.json`.
- Google Cloud Chirp 3 HD is the current AI generation workflow; the repo-side generator targets Google voices first and can still fall back to a command-template or OpenAI development path when needed.
- `tools/export_voice_over_recording_script.py` exports a narrator-friendly CSV and text script for human recording.
- `tools/verify_voice_over.py` validates catalog structure, alias targets, voice direction, and missing clip files.

## Voice Direction

All clips should sound like the same calm adult woman:

- warm and gentle
- clear for toddlers ages 2 to 5
- natural, caring-parent / preschool-teacher tone
- never loud, silly, robotic, dramatic, or rushed

## Current Completion State

The voice-over system, catalog, and generated OGG voice pack are implemented. Remaining future work is review/replacement, not first-time generation:

- Review generated clips on real devices for clarity, volume, and toddler-friendly tone.
- Replace individual generated OGG clips with human recordings if desired.
- Preserve prompt keys and filenames so no scene rewiring is needed.
