# Voice Comparison Tool

Compare TTS voices from Kokoro (local), Google Cloud Chirp 3 HD, ElevenLabs,
and Cartesia Sonic 3.5 for prerecorded game narration.

**The shipped game must never contact any cloud API.** This is a
development-time evaluation tool only.

## Prerequisites

- Python 3.10+
- WSL with Kokoro TTS installed at `~/ai-tools/kokoro-tts/`
- Google Cloud CLI (for Google Chirp 3 HD)
- Optional: ElevenLabs and/or Cartesia API keys
- Optional: ffmpeg in WSL (for format conversion and normalization)

## Setup

From the Godot project root:

```powershell
python -m venv tools\voice_comparison\.venv
tools\voice_comparison\.venv\Scripts\activate
pip install -r tools\voice_comparison\requirements.txt
```

## Supplying API Keys

**Never commit real keys.** Copy the example file and add your keys:

```powershell
copy tools\voice_comparison\.env.example tools\voice_comparison\.env
notepad tools\voice_comparison\.env
```

The `.env` file is in `.gitignore`. Environment variables take precedence.

Required for cloud providers:

| Variable | Provider |
|---|---|
| `ELEVENLABS_API_KEY` | ElevenLabs |
| `CARTESIA_API_KEY` | Cartesia |

For Google Cloud Text-to-Speech, use Application Default Credentials:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

## Checking Configuration

```powershell
python tools\voice_comparison\compare_voices.py check
```

This shows which providers are configured and their current settings.

## Listing Voices

```powershell
python tools\voice_comparison\compare_voices.py list-voices --provider google
python tools\voice_comparison\compare_voices.py list-voices --provider elevenlabs
python tools\voice_comparison\compare_voices.py list-voices --provider cartesia
```

## Generating Samples

Dry run first:

```powershell
python tools\voice_comparison\compare_voices.py generate --dry-run
```

Then generate:

```powershell
python tools\voice_comparison\compare_voices.py generate --yes
```

The tool confirms before making billable API calls. Pass `--yes` to skip the
prompt in non-interactive shells.

## Normalizing Loudness

```powershell
python tools\voice_comparison\compare_voices.py normalize
```

Targets -16 LUFS with `loudnorm` via ffmpeg (WSL). Keeps untouched originals.

## Blind Listening Test

```powershell
python tools\voice_comparison\compare_voices.py make-blind-test --seed 42
```

Creates randomized copies in `output/blind_test/` with a separate key file.

## Viewing Report

```powershell
python tools\voice_comparison\compare_voices.py report
```

## Output Layout

```
output/
├── originals/
│   ├── kokoro/       Original provider output (24000 Hz WAV)
│   ├── google/       Original provider output (24000 Hz WAV)
│   ├── elevenlabs/   Converted to common WAV format
│   └── cartesia/     Original provider output (WAV)
├── normalized/       Loudness-normalized copies
├── blind_test/       Randomized blind test copies
├── comparison.json   Full metadata for all generated files
├── comparison.csv    Evaluation template for blind testing
└── blind_test_key.json
```

## Cleaning Up

Comparison output is git-ignored. To remove generated files:

```powershell
Remove-Item -Recurse -LiteralPath tools\voice_comparison\output
```

## Credential Safety

- Keys live in `.env` (gitignored) or environment variables.
- Google ADC credentials live in `%APPDATA%\gcloud\`, never in the repo.
- The tool never prints full keys, logs tokens, or sends credentials to reports.
- The `.gitignore` covers `.env`, `.env.*`, `.venv/`, `__pycache__/`, `*.pyc`,
  and the entire `output/` directory.

## Licensing

Free-plan or trial API output is **not automatically licensed** for commercial
use in a shipped game. Verify each provider's current terms before distributing
generated audio.

- Kokoro: Apache 2.0 (local, no API restrictions)
- Google Cloud TTS: Verify Cloud Platform terms
- ElevenLabs: Verify current commercial licensing
- Cartesia: Verify current commercial licensing
