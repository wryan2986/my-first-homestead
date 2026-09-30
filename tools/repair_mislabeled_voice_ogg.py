#!/usr/bin/env python3
"""Repair voice-over files that contain WAV data but use an .ogg extension."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

try:
    import soundfile as sf
except ImportError:  # pragma: no cover - depends on local dev environment
    sf = None


VOICE_ROOT = Path("sounds") / "voice_over"
DEFAULT_ARCHIVE = Path("_assets_archive") / "audio_sources" / "mislabeled_voice_over_ogg_2026-07-01"


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert mislabeled voice-over WAV-in-OGG files to real Ogg Vorbis.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    parser.add_argument("--archive-root", default=str(DEFAULT_ARCHIVE), help="Archive folder for original files.")
    parser.add_argument("--check-only", action="store_true", help="Report mislabeled files without changing them.")
    args = parser.parse_args()

    if sf is None:
        print("ERROR: Python package 'soundfile' is required for repair.", file=sys.stderr)
        return 1

    root = Path(args.project_root).resolve()
    voice_root = root / VOICE_ROOT
    archive_root = root / args.archive_root
    mislabeled = find_mislabeled_ogg_files(voice_root)

    if args.check_only:
        for path in mislabeled:
            print(path.relative_to(root).as_posix())
        print(f"Mislabeled voice-over OGG files: {len(mislabeled)}")
        return 1 if mislabeled else 0

    for path in mislabeled:
        repair_file(root, archive_root, path)

    print(f"Repaired {len(mislabeled)} mislabeled voice-over OGG file(s).")
    return 0


def find_mislabeled_ogg_files(voice_root: Path) -> list[Path]:
    if not voice_root.exists():
        return []
    return [path for path in sorted(voice_root.rglob("*.ogg")) if read_magic(path) == b"RIFF"]


def read_magic(path: Path) -> bytes:
    with path.open("rb") as file:
        return file.read(4)


def repair_file(root: Path, archive_root: Path, path: Path) -> None:
    relative = path.relative_to(root)
    archive_path = archive_root / relative
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, archive_path)
    import_path = Path(f"{path}.import")
    if import_path.exists():
        shutil.copy2(import_path, Path(f"{archive_path}.import"))
        import_path.unlink()

    data, sample_rate = sf.read(str(path), dtype="float32", always_2d=False)
    temp_path = path.with_name(f"{path.stem}.repairing.ogg")
    sf.write(str(temp_path), data, sample_rate, format="OGG", subtype="VORBIS")
    if read_magic(temp_path) != b"OggS":
        temp_path.unlink(missing_ok=True)
        raise RuntimeError(f"Converted file is not Ogg Vorbis: {temp_path}")
    temp_path.replace(path)


if __name__ == "__main__":
    raise SystemExit(main())
