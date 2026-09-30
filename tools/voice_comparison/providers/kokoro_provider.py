from __future__ import annotations

import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

from .base import (
    COMMON_CHANNELS,
    COMMON_FORMAT,
    COMMON_SAMPLE_RATE,
    COMMON_SUFFIX,
    GenerationResult,
    SynthesisSettings,
    VoiceInfo,
    build_output_filename,
    measure_audio,
    sanitise_filename,
)

KOKORO_WSL_DIR = os.environ.get("KOKORO_WSL_DIR", "~/ai-tools/kokoro-tts")
KOKORO_VENV_ACTIVATE = f"cd {KOKORO_WSL_DIR} && source .venv/bin/activate"
KOKORO_GENERATE_SCRIPT = f"python scripts/generate_from_json.py"

DEFAULT_VOICE = "af_heart"
DEFAULT_SPEED = 0.92


def _windows_to_wsl(windows_path: Path) -> str:
    drive = windows_path.drive[0].lower()
    rest = str(windows_path.relative_to(windows_path.anchor)).replace("\\", "/")
    return f"/mnt/{drive}/{rest}"


class KokoroProvider:
    name = "kokoro"

    def __init__(self) -> None:
        self._configured: bool | None = None

    def is_configured(self) -> bool:
        if self._configured is not None:
            return self._configured
        try:
            result = subprocess.run(
                ["wsl.exe", "bash", "-lc",
                 f"{KOKORO_VENV_ACTIVATE} && python -c 'from kokoro import KPipeline; print(\"ok\")'"],
                capture_output=True, text=True, timeout=30,
            )
            self._configured = result.returncode == 0
        except Exception:
            self._configured = False
        return self._configured

    def list_voices(self) -> list[VoiceInfo]:
        known_voices = [
            ("af_heart", "female", "Heart (American English, female)"),
            ("af_bella", "female", "Bella (American English, female)"),
            ("af_nicole", "female", "Nicole (American English, female)"),
            ("af_aoede", "female", "Aoede (American English, female)"),
            ("af_kore", "female", "Kore (American English, female)"),
            ("am_adam", "male", "Adam (American English, male)"),
            ("am_michael", "male", "Michael (American English, male)"),
            ("am_onyx", "male", "Onyx (American English, male)"),
            ("am_puck", "male", "Puck (American English, male)"),
            ("bf_emma", "female", "Emma (British English, female)"),
            ("bf_isabella", "female", "Isabella (British English, female)"),
            ("bm_george", "male", "George (British English, male)"),
            ("bm_lewis", "male", "Lewis (British English, male)"),
        ]
        return [
            VoiceInfo(
                provider=self.name,
                voice_id=vid,
                name=name,
                gender=gender,
                language_codes=("en-US", "en-GB"),
            )
            for vid, gender, name in known_voices
        ]

    def synthesize(
        self,
        text: str,
        voice_id: str = DEFAULT_VOICE,
        output_path: Path | None = None,
        settings: SynthesisSettings | None = None,
    ) -> GenerationResult:
        if settings is None:
            settings = SynthesisSettings()

        start_ms = time.monotonic_ns() // 1_000_000

        if output_path is None:
            output_path = Path(tempfile.mktemp(suffix=COMMON_SUFFIX))

        output_path.parent.mkdir(parents=True, exist_ok=True)
        wsl_output = _windows_to_wsl(output_path.resolve())

        params = {
            "text": text,
            "voice": voice_id or DEFAULT_VOICE,
            "speed": settings.speaking_rate if settings.speaking_rate != 0.9 else DEFAULT_SPEED,
            "output": wsl_output,
        }
        params_json = json.dumps(params, ensure_ascii=False)

        cmd = [
            "wsl.exe", "bash", "-lc",
            f"{KOKORO_VENV_ACTIVATE} && echo {_sh_escape(params_json)} > /tmp/kokoro_params.json && {KOKORO_GENERATE_SCRIPT} /tmp/kokoro_params.json",
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            if result.returncode != 0:
                elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
                return GenerationResult(
                    provider=self.name,
                    voice_id=voice_id,
                    voice_name=voice_id,
                    model="kokoro",
                    sample_id="",
                    text=text,
                    output_path=output_path,
                    format=COMMON_FORMAT,
                    sample_rate=COMMON_SAMPLE_RATE,
                    channels=COMMON_CHANNELS,
                    duration_seconds=0.0,
                    file_size_bytes=0,
                    generation_time_ms=elapsed,
                    success=False,
                    error_message=result.stderr.strip(),
                    settings=settings,
                    character_count=len(text),
                )
        except subprocess.TimeoutExpired:
            elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
            return GenerationResult(
                provider=self.name,
                voice_id=voice_id,
                voice_name=voice_id,
                model="kokoro",
                sample_id="",
                text=text,
                output_path=output_path,
                format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE,
                channels=COMMON_CHANNELS,
                duration_seconds=0.0,
                file_size_bytes=0,
                generation_time_ms=elapsed,
                success=False,
                error_message="Kokoro WSL process timed out",
                settings=settings,
                character_count=len(text),
            )
        except Exception as exc:
            elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
            return GenerationResult(
                provider=self.name,
                voice_id=voice_id,
                voice_name=voice_id,
                model="kokoro",
                sample_id="",
                text=text,
                output_path=output_path,
                format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE,
                channels=COMMON_CHANNELS,
                duration_seconds=0.0,
                file_size_bytes=0,
                generation_time_ms=elapsed,
                success=False,
                error_message=str(exc),
                settings=settings,
                character_count=len(text),
            )

        elapsed = (time.monotonic_ns() // 1_000_000) - start_ms

        if not output_path.exists():
            return GenerationResult(
                provider=self.name,
                voice_id=voice_id,
                voice_name=voice_id,
                model="kokoro",
                sample_id="",
                text=text,
                output_path=output_path,
                format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE,
                channels=COMMON_CHANNELS,
                duration_seconds=0.0,
                file_size_bytes=0,
                generation_time_ms=elapsed,
                success=False,
                error_message="Output file was not created by Kokoro",
                settings=settings,
                character_count=len(text),
            )

        duration, sample_rate, channels, file_size = measure_audio(output_path)
        return GenerationResult(
            provider=self.name,
            voice_id=voice_id,
            voice_name=voice_id,
            model="kokoro",
            sample_id="",
            text=text,
            output_path=output_path,
            format=COMMON_FORMAT,
            sample_rate=sample_rate or COMMON_SAMPLE_RATE,
            channels=channels or COMMON_CHANNELS,
            duration_seconds=duration,
            file_size_bytes=file_size,
            generation_time_ms=elapsed,
            success=True,
            settings=settings,
            character_count=len(text),
        )


def _sh_escape(value: str) -> str:
    escaped = value.replace("'", "'\\''")
    return f"'{escaped}'"
