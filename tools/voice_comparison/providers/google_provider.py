from __future__ import annotations

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
    from google.cloud import texttospeech
    from google.cloud.texttospeech import (
        AudioConfig,
        AudioEncoding,
        SsmlVoiceGender,
        SynthesisInput,
        VoiceSelectionParams,
    )
    _GOOGLE_AVAILABLE = True
except ImportError:
    _GOOGLE_AVAILABLE = False


class GoogleProvider:
    name = "google"

    def __init__(self) -> None:
        self._client: texttospeech.TextToSpeechClient | None = None

    def _get_client(self) -> texttospeech.TextToSpeechClient | None:
        if self._client is not None:
            return self._client
        if not _GOOGLE_AVAILABLE:
            return None
        try:
            self._client = texttospeech.TextToSpeechClient()
            return self._client
        except Exception:
            return None

    def is_configured(self) -> bool:
        return self._get_client() is not None

    def list_voices(self) -> list[VoiceInfo]:
        client = self._get_client()
        if client is None:
            return []
        try:
            response = client.list_voices(language_code="en-US")
        except Exception:
            return []
        voices: list[VoiceInfo] = []
        for v in response.voices:
            gender = SsmlVoiceGender(v.ssml_gender).name if v.ssml_gender else "UNKNOWN"
            is_hd = "Chirp3-HD" in v.name
            voices.append(VoiceInfo(
                provider=self.name,
                voice_id=v.name,
                name=v.name,
                gender=gender,
                language_codes=tuple(v.language_codes),
                model="Chirp 3 HD" if is_hd else "Standard",
                is_chirp_hd=is_hd,
            ))
        return voices

    def synthesize(
        self,
        text: str,
        voice_id: str = "en-US-Chirp3-HD-Aoede",
        output_path: Path | None = None,
        settings: SynthesisSettings | None = None,
    ) -> GenerationResult:
        if settings is None:
            settings = SynthesisSettings()

        client = self._get_client()
        if client is None:
            return GenerationResult(
                provider=self.name, voice_id=voice_id, voice_name=voice_id,
                model="Chirp 3 HD", sample_id="", text=text,
                output_path=output_path or Path(), format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE, channels=COMMON_CHANNELS,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=0, success=False,
                error_message="Google TTS client not available. Check ADC setup.",
                settings=settings, character_count=len(text),
            )

        if output_path is None:
            import tempfile
            output_path = Path(tempfile.mktemp(suffix=COMMON_SUFFIX))

        output_path.parent.mkdir(parents=True, exist_ok=True)
        start_ms = time.monotonic_ns() // 1_000_000

        try:
            input_config = SynthesisInput(text=text)
            voice_config = VoiceSelectionParams(
                language_code=settings.language_code,
                name=voice_id,
            )
            audio_config = AudioConfig(
                audio_encoding=AudioEncoding.LINEAR16,
                speaking_rate=settings.speaking_rate,
                sample_rate_hertz=COMMON_SAMPLE_RATE,
            )
            response = client.synthesize_speech(
                request={"input": input_config, "voice": voice_config, "audio_config": audio_config}
            )
        except Exception as exc:
            elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
            ert = str(exc)
            return GenerationResult(
                provider=self.name, voice_id=voice_id,
                voice_name=voice_id, model="Chirp 3 HD",
                sample_id="", text=text,
                output_path=output_path, format=COMMON_FORMAT,
                sample_rate=COMMON_SAMPLE_RATE, channels=COMMON_CHANNELS,
                duration_seconds=0.0, file_size_bytes=0,
                generation_time_ms=elapsed, success=False,
                error_message=ert, settings=settings,
                character_count=len(text),
            )

        elapsed = (time.monotonic_ns() // 1_000_000) - start_ms
        output_path.write_bytes(response.audio_content)
        duration, sample_rate, channels, file_size = measure_audio(output_path)
        return GenerationResult(
            provider=self.name, voice_id=voice_id,
            voice_name=voice_id, model="Chirp 3 HD",
            sample_id="", text=text,
            output_path=output_path, format=COMMON_FORMAT,
            sample_rate=sample_rate or COMMON_SAMPLE_RATE,
            channels=channels or COMMON_CHANNELS,
            duration_seconds=duration, file_size_bytes=file_size,
            generation_time_ms=elapsed, success=True,
            settings=settings, character_count=len(text),
        )
