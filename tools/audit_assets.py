#!/usr/bin/env python3
"""Audit Godot runtime asset references.

The script compares files under the project's asset roots with `res://` paths
found in scenes, scripts, configs, JSON, and docs. It is intentionally
read-only: use it before moving or archiving assets.
"""

from __future__ import annotations

import argparse
import os
import re
from collections import Counter, defaultdict
from pathlib import Path


ASSET_ROOTS = ("art", "assets", "sounds")
SCAN_EXTENSIONS = {
    ".cfg",
    ".cs",
    ".gd",
    ".godot",
    ".json",
    ".md",
    ".tres",
    ".tscn",
}
IGNORED_DIR_PARTS = {
    ".git",
    ".godot",
    "_assets_archive",
    "__pycache__",
}
IGNORED_PREFIXES = (
    "android/build/",
    "Android game/",
)
REFERENCE_RE = re.compile(r"res://(art|assets|sounds)/[A-Za-z0-9_./()@%+* -]+")
KEEP_LIST_PATH = Path("docs/ASSET_KEEP_LIST.txt")


def normalized(path: Path) -> str:
    return path.as_posix()


def should_skip_path(path: Path) -> bool:
    path_text = normalized(path)
    if any(path_text.startswith(prefix) for prefix in IGNORED_PREFIXES):
        return True
    return any(part in IGNORED_DIR_PARTS for part in path.parts)


def trim_reference(raw: str) -> str:
    value = raw.removeprefix("res://").strip()
    return value.rstrip("`.,;:!?'\"})]")


def collect_assets(root: Path) -> set[str]:
    assets: set[str] = set()
    for asset_root in ASSET_ROOTS:
        start = root / asset_root
        if not start.exists():
            continue
        for path in start.rglob("*"):
            rel = path.relative_to(root)
            if should_skip_path(rel) or not path.is_file():
                continue
            if path.name.endswith(".import"):
                continue
            assets.add(normalized(rel))
    return assets


def collect_references(root: Path) -> tuple[set[str], dict[str, list[str]]]:
    references: set[str] = set()
    reference_sources: dict[str, list[str]] = defaultdict(list)
    for path in root.rglob("*"):
        rel = path.relative_to(root)
        if should_skip_path(rel) or not path.is_file():
            continue
        if path.suffix.lower() not in SCAN_EXTENSIONS:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in REFERENCE_RE.finditer(text):
            ref = trim_reference(match.group(0))
            if "*" in ref or "%" in ref:
                continue
            references.add(ref)
            reference_sources[ref].append(normalized(rel))
    return references, reference_sources


def load_keep_patterns(root: Path) -> list[str]:
    path = root / KEEP_LIST_PATH
    if not path.exists():
        return []
    patterns: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line == "" or line.startswith("#"):
            continue
        patterns.append(line)
    return patterns


def matches_keep_pattern(asset: str, patterns: list[str]) -> bool:
    return any(Path(asset).match(pattern) for pattern in patterns)


def print_grouped(title: str, values: list[str], limit: int | None) -> None:
    print(f"\n{title} ({len(values)})")
    print("-" * (len(title) + 5 + len(str(len(values)))))
    shown = values if limit is None else values[:limit]
    for value in shown:
        print(value)
    if limit is not None and len(values) > limit:
        print(f"... {len(values) - limit} more")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit Godot asset references.")
    parser.add_argument(
        "--root",
        default=".",
        help="Project root. Defaults to the current directory.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=80,
        help="Maximum rows per detailed section. Use 0 for no limit.",
    )
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="Exit non-zero if referenced asset paths are missing.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    limit = None if args.limit == 0 else args.limit

    assets = collect_assets(root)
    references, reference_sources = collect_references(root)
    keep_patterns = load_keep_patterns(root)

    missing = sorted(ref for ref in references if not (root / ref).exists())
    unreferenced = sorted(asset for asset in assets if asset not in references)
    retained = sorted(asset for asset in unreferenced if matches_keep_pattern(asset, keep_patterns))
    candidates = sorted(asset for asset in unreferenced if asset not in retained)

    print("Asset Audit")
    print("===========")
    print(f"Root: {root}")
    print(f"Runtime assets: {len(assets)}")
    print(f"Referenced asset paths: {len(references)}")
    print(f"Missing referenced paths: {len(missing)}")
    print(f"Unreferenced asset candidates: {len(unreferenced)}")
    print(f"Intentionally retained unreferenced assets: {len(retained)}")
    print(f"Cleanup candidates after keep-list: {len(candidates)}")

    if missing:
        print_grouped("Missing referenced paths", missing, limit)
        print("\nMissing reference sources")
        print("-------------------------")
        for ref in missing[:limit]:
            sources = ", ".join(sorted(set(reference_sources[ref]))[:6])
            print(f"{ref}: {sources}")

    folder_counts = Counter(
        "/".join(path.split("/")[:2]) if "/" in path else path for path in candidates
    )
    print("\nUnreferenced candidates by folder")
    print("---------------------------------")
    for folder, count in sorted(folder_counts.items()):
        print(f"{count:4}  {folder}")

    print_grouped("Unreferenced candidate paths", candidates, limit)
    if retained:
        print_grouped("Intentionally retained unreferenced paths", retained, limit)

    return 1 if args.fail_on_missing and missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
