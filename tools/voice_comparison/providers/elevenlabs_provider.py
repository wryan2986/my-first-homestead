from __future__ import annotations

import os
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
    measure_audio,
)

try:
    from elevenlabs import ElevenLabs
    _ELEVENLABS_AVAILABLE = True
except ImportError:
    _ELEVENLABS_AVAILABLE = False


KNOWN_VOICES: list[VoiceInfo] = [
    VoiceInfo(provider="elevenlabs", voice_id="XrExE9yKIg1WjnnlVkGX", name="Max", gender="male", language_codes=("en",), model="eleven_multilingual_v2"),
    VoiceInfo(provider="elevenlabs", voice_id="21m00Tcm4TlvDq8ikWAM", name="Rachel", gender="female", language_codes=("en",), model="eleven_multilingual_v2"),
    VoiceInfo(provider="elevenlabs", voice_id="EXAVITQu4vrMxn8k4mF", name="Bella", gender="female", language_codes=("en",), model="eleven_multilingual_v2"),
    VoiceInfo(provider="elevenlabs", voice_id="ODq5zmih8GrVes37Dizd", name="Patrick", gender="male", language_codes=("en",), model="eleven_multilingual_v2"),
]

DEFAULT_ELEVENLABS_VOICE = "XrExE9yKIg1WjnnlVkGX"


class ElevenLabsProvider:
    name = "elevenlabs"

    def __init__(self) -> None:
        self._client: ElevenLabs | None = None

    def _get_api_key(self) -> str:
        return os.environ.get("ELEVENLABS_API_KEY", "").strip()

    def _get_client(self) -> ElevenLabs | None:
        if self._client is not None:
            return self._client
        if not _ELEVENLABS_AVAILABLE:
            return None
        key = self._get_api_key()
        if not key:
            return None
        try:
            self._client = ElevenLabs(api_key=key)
            return self._client
        except Exception:
            return None

    def is_configured(self) -> bool:
        return self._get_client() is not None

    def list_voices(self) -> list[VoiceInfo]:
        try:
            client = self._get_client()
            if client is not None:
                response = client.voices.get_all()
                voices: list[VoiceInfo] = []
                for v in response.voices:
                    voices.append(VoiceInfo(
                        provider=self.name,
                        voice_id=v.voice_id,
                        name=v.name,
                        gender=v.labels.get("gender", "unknown") if v.labels else "unknown",
                        language_codes=tuple(v.language or [] if hasattr(v, "language") and v.language else ["en"]),
                        model="eleven_multilingual_v2",
                    ))
                return voices
        except Exception:
            pass
        return list(KNOWN_VOICES)

    def synthesize(
        self,
        text: str,
        voice_id: str = DEFAULT_ELEVENLABS_VOICE,
        output_path: Path | None = None,
        settings: SynthesisSettings | None = None,
    ) -> GenerationResult:
        if settings is None:
            settings = SynthesisSettings()

        client = self._get_client()
        if client is None:
            return GenerationResult(
                provider=self.name, voice_id=voice_id, voice_name=voice_id,
                model="eleven_multilingual_v2", sample_id="", text=text,
                output_path=output_path or Path(), format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE, channels=COMMON_CHANNELS,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=0, success=False,
                error_message="ElevenLabs client not available. Check ELEVENLABS_API_KEY.",
                settings=settings, character_count=len(text),
            )

        mp3_path = output_path.with_suffix(".mp3")
        mp3_path.parent.mkdir(parents=True, exist_ok=True)
        start_ms = time.monotonic_ns() // 1_000_000

        try:
            audio_data = client.text_to_speech.convert(
                voice_id=voice_id,
                text=text,
                model_id="eleven_multilingual_v2",
                output_format="mp3_44100_128",
            )
            raw = b"".join(chunk for chunk in audio_data if chunk)
        except Exception as exc:
            elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
            return GenerationResult(
                provider=self.name, voice_id=voice_id,
                voice_name=voice_id, model="eleven_multilingual_v2",
                sample_id="", text=text,
                output_path=mp3_path, format="MP3",
                sample_rate=0, channels=0,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=elapsed, success=False,
                error_message=str(exc), settings=settings,
                character_count=len(text),
            )

        elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
        mp3_path.write_bytes(raw)

        wav_path = output_path  # caller already set this to .wav path
        converted = _convert_to_wav(mp3_path, wav_path)

        if converted and wav_path.exists():
            mp3_path.unlink(missing_ok=True)
            elapsed_full = (time.monotonic_ns() // 1_000_000) - start_ms
            duration, sample_rate, channels, file_size = measure_audio(wav_path)
            return GenerationResult(
                provider=self.name, voice_id=voice_id,
                voice_name=voice_id, model="eleven_multilingual_v2",
                sample_id="", text=text,
                output_path=wav_path, format=COMMON_FORMAT,
                sample_rate=sample_rate or COMMON_SAMPLE_RATE,
                channels=channels or COMMON_CHANNELS,
                duration_seconds=duration, file_size_bytes=file_size,
                generation_time_ms=elapsed_full, success=True,
                settings=settings, character_count=len(text),
            )
        else:
            elapsed_full = (time.monotonic_ns() // 1_000_000) - start_ms
            duration, sample_rate, channels, file_size = measure_audio(mp3_path)
            return GenerationResult(
                provider=self.name, voice_id=voice_id,
                voice_name=voice_id, model="eleven_multilingual_v2",
                sample_id="", text=text,
                output_path=mp3_path, format="MP3",
                sample_rate=sample_rate, channels=channels or 2,
                duration_seconds=duration, file_size_bytes=file_size,
                generation_time_ms=elapsed_full, success=False,
                error_message="Could not convert MP3 to WAV (ffmpeg missing?)",
                settings=settings, character_count=len(text),
            )


def _convert_to_wav(src: Path, dst: Path) -> bool:
    import subprocess
    for attempt in [
        ["wsl.exe", "ffmpeg", "-y", "-i", _wsl_path(src),
         "-ac", str(COMMON_CHANNELS), "-ar", str(COMMON_SAMPLE_RATE),
         "-c:a", "pcm_s16le", _wsl_path(dst)],
        ["ffmpeg", "-y", "-i", str(src),
         "-ac", str(COMMON_CHANNELS), "-ar", str(COMMON_SAMPLE_RATE),
         "-c:a", "pcm_s16le", str(dst)],
    ]:
        try:
            subprocess.run(attempt, capture_output=True, text=True, timeout=60)
            if dst.exists() and dst.stat().st_size > 0:
                return True
        except Exception:
            continue
    return False


def _wsl_path(p: Path) -> str:
    drive = p.drive[0].lower()
    rest = str(p.relative_to(p.anchor)).replace("\\", "/")
    return f"/mnt/{drive}/{rest}"
