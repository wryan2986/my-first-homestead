from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

from .base import (
    COMMON_CHANNELS,
    COMMON_FORMAT,
    COMMON_SAMPLE_RATE,
    COMMON_SUFFIX,
    GenerationResult,
    SynthesisSettings,
    VoiceInfo,
    measure_audio,
)

CARTESIA_API_BASE = "https://api.cartesia.ai"
CARTESIA_TTS_URL = f"{CARTESIA_API_BASE}/v1/tts/stream"
CARTESIA_VOICES_URL = f"{CARTESIA_API_BASE}/v1/voices"
DEFAULT_MODEL = "sonic-3.5"
DEFAULT_VOICE = "a8871e61-4b73-4a8a-9341-7cc3be7fcfb9"


class CartesiaProvider:
    name = "cartesia"

    def __init__(self) -> None:
        self._voices_cache: list[VoiceInfo] | None = None

    def _get_api_key(self) -> str:
        return os.environ.get("CARTESIA_API_KEY", "").strip()

    def is_configured(self) -> bool:
        key = self._get_api_key()
        if not key:
            return False
        return key.startswith("sk_car") and len(key) >= 20

    def list_voices(self) -> list[VoiceInfo]:
        if self._voices_cache is not None:
            return self._voices_cache
        key = self._get_api_key()
        if not key:
            return []
        try:
            from cartesia import Cartesia as _Cartesia
            client = _Cartesia(api_key=key)
            raw_voices = client.voices.list()
            voices: list[VoiceInfo] = []
            for v in raw_voices:
                vid = v.id
                name = v.name
                mode = getattr(v, "mode", "similarity")
                gender = "unknown"
                if hasattr(v, "labels") and v.labels:
                    if isinstance(v.labels, dict):
                        gender = v.labels.get("gender", "unknown")
                voices.append(VoiceInfo(
                    provider=self.name,
                    voice_id=vid,
                    name=name,
                    gender=gender,
                    language_codes=("en-US",),
                    model=DEFAULT_MODEL,
                ))
            self._voices_cache = voices
            return voices
        except Exception:
            return []

    def synthesize(
        self,
        text: str,
        voice_id: str = DEFAULT_VOICE,
        output_path: Path | None = None,
        settings: SynthesisSettings | None = None,
    ) -> GenerationResult:
        if settings is None:
            settings = SynthesisSettings()

        key = self._get_api_key()
        if not key:
            return GenerationResult(
                provider=self.name, voice_id=voice_id, voice_name=voice_id,
                model=DEFAULT_MODEL, sample_id="", text=text,
                output_path=output_path or Path(), format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE, channels=COMMON_CHANNELS,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=0, success=False,
                error_message="Cartesia API key not set. Check CARTESIA_API_KEY.",
                settings=settings, character_count=len(text),
            )

        if output_path is None:
            import tempfile
            output_path = Path(tempfile.mktemp(suffix=COMMON_SUFFIX))

        output_path.parent.mkdir(parents=True, exist_ok=True)
        start_ms = time.monotonic_ns() // 1_000_000

        try:
            from cartesia import Cartesia as _Cartesia
            client = _Cartesia(api_key=key)
            response = client.tts.generate(
                model_id=DEFAULT_MODEL,
                transcript=text,
                voice={"mode": "id", "id": voice_id},
                output_format={
                    "container": "wav",
                    "encoding": "pcm_s16le",
                    "sample_rate": COMMON_SAMPLE_RATE,
                },
            )
            raw = b"".join(response.iter_bytes())
        except Exception as exc:
            elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
            return GenerationResult(
                provider=self.name, voice_id=voice_id,
                voice_name=voice_id, model=DEFAULT_MODEL,
                sample_id="", text=text,
                output_path=output_path, format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE, channels=COMMON_CHANNELS,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=elapsed, success=False,
                error_message=str(exc),
                settings=settings, character_count=len(text),
            )

        elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
        output_path.write_bytes(raw)
        duration, sample_rate, channels, file_size = measure_audio(output_path)
        return GenerationResult(
            provider=self.name, voice_id=voice_id,
            voice_name=voice_id, model=DEFAULT_MODEL,
            sample_id="", text=text,
            output_path=output_path, format=COMMON_FORMAT,
            sample_rate=sample_rate or COMMON_SAMPLE_RATE,
            channels=channels or COMMON_CHANNELS,
            duration_seconds=duration, file_size_bytes=file_size,
            generation_time_ms=elapsed, success=True,
            settings=settings, character_count=len(text),
        )
