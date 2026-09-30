#!/usr/bin/env python3
"""Report the compressed payload of an Android App Bundle.

The Android App Bundle is the useful comparison point for this project because
it is the artifact sent to Google Play.  The report groups ZIP entries by
payload type and shows the largest imported texture/audio/font entries so an
accidental asset inclusion is easy to spot.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from zipfile import ZipFile


TARGET_MB = 150.0


@dataclass(frozen=True)
class BundleStats:
    path: Path
    zip_bytes: int
    compressed_by_type: dict[str, int]
    uncompressed_by_type: dict[str, int]
    compressed_by_module: dict[str, int]
    largest_entries: tuple[tuple[str, int, int], ...]


def format_bytes(value: int) -> str:
    return f"{value / 1_000_000:.2f} MB ({value / 1_048_576:.2f} MiB)"


def entry_type(name: str) -> str:
    suffix = Path(name).suffix.lower()
    if suffix:
        return suffix.removeprefix(".")
    return "no-extension"


def read_bundle(path: Path) -> BundleStats:
    compressed_by_type: defaultdict[str, int] = defaultdict(int)
    uncompressed_by_type: defaultdict[str, int] = defaultdict(int)
    compressed_by_module: defaultdict[str, int] = defaultdict(int)
    entries: list[tuple[str, int, int]] = []

    with ZipFile(path) as bundle:
        for info in bundle.infolist():
            if info.is_dir():
                continue
            kind = entry_type(info.filename)
            compressed_by_type[kind] += info.compress_size
            uncompressed_by_type[kind] += info.file_size
            module = info.filename.split("/", 1)[0]
            compressed_by_module[module] += info.compress_size
            entries.append((info.filename, info.compress_size, info.file_size))

    entries.sort(key=lambda item: item[1], reverse=True)
    return BundleStats(
        path=path,
        zip_bytes=path.stat().st_size,
        compressed_by_type=dict(compressed_by_type),
        uncompressed_by_type=dict(uncompressed_by_type),
        compressed_by_module=dict(compressed_by_module),
        largest_entries=tuple(entries[:20]),
    )


def print_bundle(stats: BundleStats) -> None:
    print(f"Bundle: {stats.path}")
    print(f"File size: {format_bytes(stats.zip_bytes)}")
    print()

    print("Compressed payload by file type:")
    for kind, size in sorted(stats.compressed_by_type.items(), key=lambda item: item[1], reverse=True):
        unpacked = stats.uncompressed_by_type[kind]
        print(f"  {kind:16} {format_bytes(size):>25}  unpacked {format_bytes(unpacked)}")

    print()
    print("Compressed payload by module:")
    for module, size in sorted(stats.compressed_by_module.items(), key=lambda item: item[1], reverse=True):
        print(f"  {module:24} {format_bytes(size)}")

    print()
    print("Largest entries:")
    for name, compressed, unpacked in stats.largest_entries:
        print(f"  {format_bytes(compressed):>25}  {name}  (unpacked {format_bytes(unpacked)})")


def print_comparison(before: BundleStats, after: BundleStats) -> None:
    print()
    print("Comparison:")
    delta = after.zip_bytes - before.zip_bytes
    direction = "smaller" if delta < 0 else "larger"
    print(
        f"  {before.path.name}: {format_bytes(before.zip_bytes)}"
        f" -> {after.path.name}: {format_bytes(after.zip_bytes)}"
    )
    print(f"  Change: {format_bytes(abs(delta))} {direction}")

    kinds = sorted(set(before.compressed_by_type) | set(after.compressed_by_type))
    print("  File-type changes:")
    for kind in kinds:
        old = before.compressed_by_type.get(kind, 0)
        new = after.compressed_by_type.get(kind, 0)
        change = new - old
        print(f"    {kind:16} {format_bytes(old):>25} -> {format_bytes(new):>25}  ({change:+,} bytes)")


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect Android App Bundle size.")
    parser.add_argument("aab", type=Path, help="Path to the Android App Bundle.")
    parser.add_argument(
        "--compare",
        type=Path,
        metavar="OLD_AAB",
        help="Compare the selected bundle with an older bundle.",
    )
    parser.add_argument(
        "--fail-over-mb",
        type=float,
        default=None,
        metavar="MB",
        help=f"Return failure when the AAB is larger than this decimal MB threshold (default target: {TARGET_MB:g}).",
    )
    args = parser.parse_args()

    bundle_path = args.aab.resolve()
    if not bundle_path.exists():
        parser.error(f"AAB not found: {bundle_path}")

    stats = read_bundle(bundle_path)
    print_bundle(stats)

    if args.compare:
        before_path = args.compare.resolve()
        if not before_path.exists():
            parser.error(f"Comparison AAB not found: {before_path}")
        print_comparison(read_bundle(before_path), stats)

    threshold = args.fail_over_mb
    if threshold is not None and stats.zip_bytes > threshold * 1_000_000:
        print(f"\nFAIL: bundle is over the {threshold:g} MB threshold.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
