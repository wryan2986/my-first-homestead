#!/usr/bin/env python3
"""Report simple duration and level data for project audio files."""

from __future__ import annotations

import argparse
import io
import math
import shutil
import struct
import subprocess
import wave
from pathlib import Path


AUDIO_EXTENSIONS = {".wav", ".ogg", ".mp3", ".flac"}


def db(value: float) -> float:
    if value <= 0.0:
        return float("-inf")
    return 20.0 * math.log10(value)


def wav_stats(path: Path) -> tuple[float | None, float, float, str]:
    data = path.read_bytes()
    parsed = parse_wav(data)
    if parsed is None:
        try:
            with wave.open(str(path), "rb") as wav:
                channels = wav.getnchannels()
                sample_width = wav.getsampwidth()
                frame_rate = wav.getframerate()
                frames = wav.getnframes()
                pcm_data = wav.readframes(frames)
        except wave.Error as error:
            return ffprobe_duration(path), float("nan"), float("nan"), f"WAV level unavailable: {error}"
        duration = frames / float(frame_rate) if frame_rate > 0 else 0.0
        if sample_width != 2 or not pcm_data:
            return duration, float("nan"), float("nan"), "WAV level unavailable: unsupported sample width"
        count = len(pcm_data) // 2
        samples = [sample / 32768.0 for sample in struct.unpack("<" + "h" * count, pcm_data)]
    else:
        audio_format, channels, frame_rate, bits_per_sample, pcm_data = parsed
        bytes_per_sample = max(1, bits_per_sample // 8)
        frame_bytes = max(1, bytes_per_sample * max(1, channels))
        duration = (len(pcm_data) / frame_bytes) / float(frame_rate) if frame_rate > 0 else 0.0
        samples = decode_samples(pcm_data, audio_format, bits_per_sample)
        if samples is None:
            return duration, float("nan"), float("nan"), f"WAV level unavailable: unsupported format {audio_format}/{bits_per_sample}"
    if not samples:
        return duration, float("nan"), float("nan"), "WAV level unavailable: no samples"
    peak = max(abs(sample) for sample in samples)
    rms = math.sqrt(sum(sample * sample for sample in samples) / max(1, len(samples)))
    if channels > 1:
        rms = min(1.0, rms * math.sqrt(channels))
    return duration, db(peak), db(rms), ""


def parse_wav(data: bytes) -> tuple[int, int, int, int, bytes] | None:
    if len(data) < 12 or data[0:4] != b"RIFF" or data[8:12] != b"WAVE":
        return None
    audio_format = channels = frame_rate = bits_per_sample = None
    audio_data = None
    offset = 12
    while offset + 8 <= len(data):
        chunk_id = data[offset:offset + 4]
        chunk_size = struct.unpack_from("<I", data, offset + 4)[0]
        chunk_start = offset + 8
        chunk_end = min(len(data), chunk_start + chunk_size)
        chunk = data[chunk_start:chunk_end]
        if chunk_id == b"fmt " and len(chunk) >= 16:
            audio_format, channels, frame_rate, _byte_rate, _block_align, bits_per_sample = struct.unpack_from("<HHIIHH", chunk, 0)
        elif chunk_id == b"data":
            audio_data = chunk
        offset = chunk_end + (chunk_size % 2)
    if audio_format is None or channels is None or frame_rate is None or bits_per_sample is None or audio_data is None:
        return None
    return audio_format, channels, frame_rate, bits_per_sample, audio_data


def decode_samples(data: bytes, audio_format: int, bits_per_sample: int) -> list[float] | None:
    if audio_format == 1 and bits_per_sample == 16:
        count = len(data) // 2
        return [sample / 32768.0 for sample in struct.unpack("<" + "h" * count, data[:count * 2])]
    if audio_format == 1 and bits_per_sample == 8:
        return [(byte - 128) / 128.0 for byte in data]
    if audio_format == 3 and bits_per_sample == 32:
        count = len(data) // 4
        return list(struct.unpack("<" + "f" * count, data[:count * 4]))
    return None


def ogg_vorbis_duration(path: Path) -> float | None:
    data = path.read_bytes()
    sample_rate = None
    final_granule = None
    stream = io.BytesIO(data)
    while True:
        header = stream.read(27)
        if len(header) == 0:
            break
        if len(header) < 27 or header[0:4] != b"OggS":
            return None
        granule = struct.unpack_from("<q", header, 6)[0]
        segment_count = header[26]
        lacing = stream.read(segment_count)
        if len(lacing) < segment_count:
            return None
        page_size = sum(lacing)
        page_data = stream.read(page_size)
        if len(page_data) < page_size:
            return None
        if sample_rate is None:
            index = page_data.find(b"\x01vorbis")
            if index >= 0 and index + 16 <= len(page_data):
                sample_rate = struct.unpack_from("<I", page_data, index + 12)[0]
        if granule >= 0:
            final_granule = granule
    if sample_rate is None or sample_rate <= 0 or final_granule is None:
        return None
    return final_granule / float(sample_rate)


def ffprobe_duration(path: Path) -> float | None:
    ffprobe = shutil.which("ffprobe")
    if ffprobe == "":
        ffprobe = None
    if ffprobe is not None:
        command = [
            ffprobe,
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(path),
        ]
        return run_ffprobe_duration(command)
    wsl = shutil.which("wsl.exe")
    if wsl is None:
        return None
    wsl_path = windows_path_to_wsl(path)
    command = [
        wsl,
        "-e",
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        wsl_path,
    ]
    return run_ffprobe_duration(command)


def run_ffprobe_duration(command: list[str]) -> float | None:
    completed = subprocess.run(command, capture_output=True, text=True, timeout=10)
    if completed.returncode != 0:
        return None
    try:
        return float(completed.stdout.strip())
    except ValueError:
        return None


def windows_path_to_wsl(path: Path) -> str:
    resolved = path.resolve()
    drive = resolved.drive.rstrip(":").lower()
    rest = resolved.as_posix().split(":", 1)[1].lstrip("/")
    return f"/mnt/{drive}/{rest}"


def audio_files(root: Path) -> list[Path]:
    results: list[Path] = []
    for folder in (root / "sounds", root / "assets" / "music"):
        if not folder.exists():
            continue
        for path in folder.rglob("*"):
            if path.is_file() and path.suffix.lower() in AUDIO_EXTENSIONS:
                results.append(path)
    return sorted(results)


def format_rows(root: Path, rows: list[tuple[str, str, float | None, float | None, float | None, str]]) -> str:
    output: list[str] = []
    output.append("Audio Loudness Audit")
    output.append("====================")
    output.append(f"Root: {root}")
    output.append(f"Files: {len(rows)}")
    output.append("")
    output.append(f"{'file':68} {'type':4} {'sec':>8} {'peak':>9} {'rms':>9}  note")
    output.append("-" * 108)
    for rel, kind, duration, peak, rms, note in rows:
        duration_text = "n/a" if duration is None else f"{duration:0.2f}"
        peak_text = "n/a" if peak is None or math.isnan(peak) else f"{peak:0.1f}"
        rms_text = "n/a" if rms is None or math.isnan(rms) else f"{rms:0.1f}"
        output.append(f"{rel[:68]:68} {kind:4} {duration_text:>8} {peak_text:>9} {rms_text:>9}  {note}")
    output.append("")
    flagged = [row for row in rows if row[5]]
    long_clips = [row for row in rows if row[2] is not None and row[2] > 120.0]
    tiny_clips = [row for row in rows if row[2] is not None and row[2] < 0.12]
    output.append("Review Summary")
    output.append("--------------")
    output.append(f"Flagged clips: {len(flagged)}")
    output.append(f"Long clips over 120s: {len(long_clips)}")
    output.append(f"Very short clips under 0.12s: {len(tiny_clips)}")
    if flagged:
        output.append("")
        output.append("Flagged files:")
        for rel, _kind, _duration, _peak, _rms, note in flagged:
            output.append(f"- {rel}: {note}")
    return "\n".join(output)


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit project audio duration and loudness.")
    parser.add_argument("--root", default=".", help="Project root.")
    parser.add_argument("--warn-peak-above", type=float, default=-1.0, help="Warn when WAV peak dBFS is above this.")
    parser.add_argument("--warn-rms-above", type=float, default=-10.0, help="Warn when WAV RMS dBFS is above this.")
    parser.add_argument("--report", default="", help="Optional text report path, relative to root unless absolute.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    rows: list[tuple[str, str, float | None, float | None, float | None, str]] = []
    for path in audio_files(root):
        rel = path.relative_to(root).as_posix()
        duration: float | None
        peak: float | None
        rms: float | None
        note = ""
        if path.suffix.lower() == ".wav":
            duration, peak, rms, note = wav_stats(path)
            if not math.isnan(peak) and peak > args.warn_peak_above:
                note = "peak hot"
            if not math.isnan(rms) and rms > args.warn_rms_above:
                note = f"{note}; rms loud".strip("; ")
        else:
            duration = ogg_vorbis_duration(path) if path.suffix.lower() == ".ogg" else None
            if duration is None:
                duration = ffprobe_duration(path)
            peak = None
            rms = None
            if duration is None:
                note = "duration unavailable; install ffprobe or use WSL ffprobe"
        rows.append((rel, path.suffix.lower().removeprefix("."), duration, peak, rms, note))

    report_text = format_rows(root, rows)
    print(report_text)
    if args.report:
        report_path = Path(args.report)
        if not report_path.is_absolute():
            report_path = root / report_path
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(report_text + "\n", encoding="utf-8")
        print(f"\nWrote {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
