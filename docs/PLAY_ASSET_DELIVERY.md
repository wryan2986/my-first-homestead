# Play Asset Delivery Layout

This project keeps the shared English voice prompts in the base Android App Bundle and treats localized voice packs, localized fonts, and optional HD background art as separate Play Asset Delivery assets.

## Base bundle

Keep these in the base export:

- `res://sounds/voice_over/*.ogg`
- `res://sounds/voice_over/voice_lines.json`
- `res://sounds/voice_over/locales/en-US/santa_full_greeting.ogg`

The base bundle should not include the full locale tree.

The base game remains playable offline. If a locale pack is unavailable, the game uses the base font/system fallback and platform text-to-speech fallback for missing localized audio.

## Locale packs

Place the shipped locale packs in:

- `res://sounds/voice_over/locales/es/`
- `res://sounds/voice_over/locales/fr/`
- `res://sounds/voice_over/locales/pt-BR/`
- `res://sounds/voice_over/locales/de/`
- `res://sounds/voice_over/locales/it/`
- `res://sounds/voice_over/locales/zh-CN/`
- `res://sounds/voice_over/locales/ja/`
- `res://sounds/voice_over/locales/ko/`
- `res://sounds/voice_over/locales/ar/`
- `res://sounds/voice_over/locales/hi/`

Each locale folder should contain its own `voice_lines.json`. Historical `santa_full_greeting.ogg` clips may exist in regional folders, but runtime Santa playback now uses the full greeting only for English and uses the short ho-ho SFX for non-English languages.

Regional Santa greetings are tracked separately so they can be packed as seasonal assets:

- `res://sounds/voice_over/locales/en-US/`
- `res://sounds/voice_over/locales/es-US/`
- `res://sounds/voice_over/locales/fr-FR/`
- `res://sounds/voice_over/locales/de-DE/`
- `res://sounds/voice_over/locales/it-IT/`
- `res://sounds/voice_over/locales/pt-BR/`

## Play Console setup

When configuring Play Asset Delivery, use one asset pack per locale. A simple naming scheme is:

- `voice_es`
- `voice_fr`
- `voice_pt_br`
- `voice_de`
- `voice_it`
- `voice_zh_cn`
- `voice_ja`
- `voice_ko`
- `voice_ar`
- `voice_hi`

Optional high-density background art should use a separate `backgrounds_hd` pack with on-demand delivery. The base package uses the 1600x900 background tier; the HD pack contains the archived 1920x1080 versions and is selected only after its files are available.

If seasonal Santa greeting packs are kept for archive or future review, use a separate pack naming scheme such as:

- `santa_en_us`
- `santa_es_us`
- `santa_fr_fr`
- `santa_de_de`
- `santa_it_it`
- `santa_pt_br`

Use `fast-follow` or `on-demand` delivery so those packs do not download with the base install. Keep the base bundle small and verify the uploaded AAB does not accidentally include the locale tree.

To print the current pack list from the repo, run:

```powershell
python tools\print_play_asset_delivery_packs.py
```

## Runtime behavior

`scripts/core/VoiceOverManager.gd` loads the active locale first, then falls back to the shared catalog, and finally to platform TTS if a clip is missing. Santa is intentionally different: `scripts/ui/SantaSleighFlyer.gd` uses the full Santa greeting only for English locales and uses the existing ho-ho SFX for non-English locales.
