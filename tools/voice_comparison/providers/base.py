from __future__ import annotations

import dataclasses
import time
from pathlib import Path
from typing import Protocol, runtime_checkable


@dataclasses.dataclass(frozen=True)
class VoiceInfo:
    provider: str
    voice_id: str
    name: str
    gender: str
    language_codes: tuple[str, ...]
    model: str = ""
    is_chirp_hd: bool = False


@dataclasses.dataclass
class SynthesisSettings:
    language_code: str = "en-US"
    speaking_rate: float = 0.9
    sample_rate: int = 24000


@dataclasses.dataclass
class GenerationResult:
    provider: str
    voice_id: str
    voice_name: str
    model: str
    sample_id: str
    text: str
    output_path: Path
    format: str
    sample_rate: int
    channels: int
    duration_seconds: float
    file_size_bytes: int
    generation_time_ms: float
    success: bool
    error_message: str = ""
    settings: SynthesisSettings | None = None
    character_count: int = 0


COMMON_SAMPLE_RATE = 24000
COMMON_CHANNELS = 1
COMMON_FORMAT = "WAV"
COMMON_SUFFIX = ".wav"


@runtime_checkable
class VoiceProvider(Protocol):
    @property
    def name(self) -> str:
        ...

    def is_configured(self) -> bool:
        ...

    def list_voices(self) -> list[VoiceInfo]:
        ...

    def synthesize(
        self,
        text: str,
        voice_id: str,
        output_path: Path,
        settings: SynthesisSettings | None = None,
    ) -> GenerationResult:
        ...


def sanitise_filename(value: str) -> str:
    import re
    sanitised = re.sub(r"[^a-z0-9_]+", "_", value.lower())
    return sanitised.strip("_")


def build_output_filename(provider: str, voice_name: str, sample_id: str) -> str:
    p = sanitise_filename(provider)
    v = sanitise_filename(voice_name)
    s = sanitise_filename(sample_id)
    return f"{p}__{v}__{s}{COMMON_SUFFIX}"


def measure_audio(path: Path) -> tuple[float, int, int, int]:
    import subprocess
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "error",
             "-show_entries", "stream=duration,sample_rate,channels",
             "-of", "csv=p=0",
             str(path)],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode == 0 and result.stdout.strip():
            parts = result.stdout.strip().split(",")
            duration = float(parts[0]) if parts[0] else 0.0
            sample_rate = int(parts[1]) if len(parts) > 1 and parts[1] else 0
            channels = int(parts[2]) if len(parts) > 2 and parts[2] else 0
            return duration, sample_rate, channels, path.stat().st_size
    except Exception:
        pass
    return 0.0, 0, 0, path.stat().st_size
