# Voice-Over Pipeline

The game uses voice-over sparingly: only chore trouble tips and chore completion messages should speak. Do not add narration for scene titles, progress labels, settings labels, farmyard status text, or routine tap feedback.

The AI-vs-human voice decision is captured in `docs/VOICE_OVER_DECISION.md`.

## Voice Direction

- Use the same calm adult woman voice for every line.
- Keep delivery warm, gentle, clear, and reassuring.
- Speak a little slowly for toddlers ages 2 to 5.
- Avoid silly, loud, dramatic, robotic, or rushed delivery.

## Catalog

Voice lines are cataloged in:

```text
res://sounds/voice_over/voice_lines.json
```

Each line has:

- `key`: stable prompt key used by scripts.
- `text`: exact line to speak.
- `path`: target `.ogg` file.
- `notes`: recording or usage guidance.

Aliases map dynamic animal-specific hint keys, such as `feeding_hint_pig_gentle`, to shared audio clips, such as `feeding_hint_gentle`.

Locale-specific prompt packs live beside the shared catalog under:

```text
res://sounds/voice_over/locales/<locale>/voice_lines.json
```

The runtime first looks for a locale pack that matches the active locale. If it does not find one, or if a specific key is missing, it falls back to the shared catalog and then to platform TTS when enabled.

Locale-specific special clips that are not part of the main prompt catalog, such as archived regional Santa greeting candidates, also live under the same locale folder so the entire locale bundle stays together:

```text
res://sounds/voice_over/locales/<locale>/santa_full_greeting.ogg
```

`scripts/ui/SantaSleighFlyer.gd` only uses the full Santa greeting for English locales. Non-English locales deliberately fall through to the existing short ho-ho SFX so Santa never mixes a recorded greeting with local/device TTS or a mismatched language clip.

## Generating AI Voice Clips

The current generated voice pack is built with Google Cloud Chirp 3 HD and imported as `.ogg` files. The app never calls a cloud voice service at runtime.

```powershell
python tools\verify_voice_over.py
python tools\verify_voice_over.py --strict-files
python tools\verify_localization.py
Godot_v4.6.2-stable_win64_console.exe --headless --path . --import
```

The voice generator uses Google Cloud Application Default Credentials configured on the developer machine. Do not store credentials in the repository.

Use that workflow when regenerating the pack. Keep filenames and catalog keys stable, convert accepted clips to OGG, and rerun the verification/import steps above.

Translated voice prompt text lives in `localization/voice_prompts/<locale>.json`. Godot loads those prompt catalogs alongside the main UI translations, and `tools/generate_voice_over.py` uses the same prompt text when it builds each locale pack.

When adding a shipped locale, use the local generation pipeline to build the matching locale catalog under `sounds/voice_over/locales/<locale>/` and keep the prompt keys identical so `VoiceOverManager.gd` can fall back cleanly if one clip is missing.

For locale pack generation, the repo now supports a Google TTS workflow:

```powershell
python tools\google_generate_locale_packs.py --project-root .
```

The repo still supports a generic command-template fallback in `tools/generate_voice_over.py` for developer-only experiments, but the shipped workflow should use Google voices.

Do not commit voice service credentials or model tokens. Do not add internet permissions or runtime cloud voice calls to the toddler app.

## Human Recording Replacement

Human recordings can replace AI clips directly:

1. Export the narrator packet:

   ```powershell
   python tools\export_voice_over_recording_script.py
   ```

2. Give the narrator the generated files under `docs/voice_over_recording/`.
3. Record the same catalog text with one female speaker in a quiet session.
4. Export each accepted take as `.ogg` using the listed filename, or export WAV masters and convert them to matching OGG files before import.
5. Save each clip to the matching `res://sounds/voice_over/` path.
6. Run `python tools\verify_voice_over.py --strict-files`.
7. Run Godot import.
8. Test hints and completions in game.

No scene rewiring is needed if filenames and prompt keys stay the same.

## Implementation Notes

`VoiceOverManager.gd` prefers localized recorded clips first, then shared recorded clips, and falls back to Godot platform TTS only when a clip is missing. `FarmState.get_chore_completion_feedback()` returns both visible completion text and the matching voice key so subtitles and audio stay synchronized.
