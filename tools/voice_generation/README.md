# Google Cloud Chirp 3 HD Narration Generator

Development-time tool to generate prerecorded narration audio for Farm Chore
Friends using Google Cloud Text-to-Speech with Chirp 3 HD voices.

**The shipped game must never contact Google Cloud, contain credentials, or
depend on internet access.** This is a developer-only asset pipeline.

## Prerequisites

1.  **Google Cloud CLI** — Download and install from
    https://cloud.google.com/sdk/docs/install

2.  **Google Cloud project** with billing enabled.
    https://cloud.google.com/text-to-speech/pricing

    Billing must generally be enabled even when usage falls within free
    allowances. Check current pricing at the link above.

3.  **Enable the Text-to-Speech API:**
    ```powershell
    gcloud services enable texttospeech.googleapis.com
    ```

4.  **Authenticate locally** (one-time interactive login):
    ```powershell
    gcloud auth application-default login
    gcloud auth application-default set-quota-project YOUR_PROJECT_ID
    ```

    This opens a browser to sign in with your Google account. Never commit
    credential files to the repository.

5.  **Python 3.10+** — This project bundles Python 3.13.

## Setup

From the Godot project root:

```powershell
cd tools\voice_generation
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Usage

Run all commands from the **Godot project root** (where `project.godot` lives).

### List available Chirp 3 HD voices
```powershell
python tools\voice_generation\generate_voice.py --list-voices
```

### Generate a single line
```powershell
python tools\voice_generation\generate_voice.py ^
  --text "Let's collect the eggs!" ^
  --id collect_eggs_prompt ^
  --output-dir sounds/voice_over
```

### Generate from manifest
```powershell
python tools\voice_generation\generate_voice.py ^
  --manifest tools\voice_generation\narration_manifest.json ^
  --output-dir sounds/voice_over
```

### Dry run (validate manifest, no API call)
```powershell
python tools\voice_generation\generate_voice.py ^
  --manifest tools\voice_generation\narration_manifest.json --dry-run
```

### Convert to OGG after generation
```powershell
python tools\voice_generation\generate_voice.py ^
  --manifest tools\voice_generation\narration_manifest.json ^
  --output-dir sounds/voice_over --ogg
```

Requires ffmpeg in WSL (available at `/usr/bin/ffmpeg`).

## Output

- Default format: **WAV** (LINEAR16, 24 kHz, mono).
- Optional format: **OGG Vorbis** (44.1 kHz, mono, quality 4) via `--ogg`.
- Files are named `{sanitised_id}.wav` (or `.ogg`).
- Existing files are **not overwritten** unless you pass `--overwrite`.

Generated files go into `sounds/voice_over/` by default, which is the same
directory the game's `VoiceOverManager` reads from.

## Integration with the Game

1. Generated WAV (or OGG) files in `sounds/voice_over/`.
2. Open the Godot project — Godot automatically imports new audio files.
3. `VoiceOverManager` will find the file when `speak()` is called with the
   matching `prompt_key` (e.g. `speak("text", "collect_eggs_prompt")`).

No catalog JSON update is required. The manager falls back to a convention:
`res://sounds/voice_over/{prompt_key}.wav` or `.ogg`.

## Credential Safety

- Credentials live in your home directory
  (`%APPDATA%\gcloud\application_default_credentials.json`), never in the
  repository.
- The `.gitignore` already ignores `.venv/`, `__pycache__/`, and `*.pyc`.
- Generated audio files are normal project assets and should be committed.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `gcloud: command not found` | Install Google Cloud SDK |
| `ADC not found` | Run `gcloud auth application-default login` |
| `Project not set` | Run `gcloud config set project PROJECT_ID` |
| `API not enabled` | Run `gcloud services enable texttospeech.googleapis.com` |
| `Billing not enabled` | Enable billing in Cloud Console |
| `Missing google-cloud-texttospeech` | Activate venv and `pip install -r requirements.txt` |
