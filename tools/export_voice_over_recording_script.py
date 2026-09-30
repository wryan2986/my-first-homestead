#!/usr/bin/env python3
"""Export human voice-over recording scripts from the voice line catalog."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import sys


DEFAULT_CATALOG = Path("sounds") / "voice_over" / "voice_lines.json"
DEFAULT_OUTPUT_DIR = Path("docs") / "voice_over_recording"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create CSV and text scripts for recording voice-over lines."
    )
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    parser.add_argument("--catalog", default=str(DEFAULT_CATALOG), help="Voice line JSON catalog.")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR), help="Output folder.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    catalog_path = _resolve_project_path(project_root, args.catalog)
    output_dir = _resolve_project_path(project_root, args.output_dir)

    if not catalog_path.exists():
        print(f"Voice catalog not found: {catalog_path}", file=sys.stderr)
        return 1

    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    lines = catalog.get("lines", [])
    if not isinstance(lines, list) or not lines:
        print("Voice catalog has no lines.", file=sys.stderr)
        return 1

    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / "voice_over_recording_script.csv"
    txt_path = output_dir / "voice_over_recording_script.txt"

    normalized_lines = []
    for line in lines:
        if not isinstance(line, dict):
            continue
        key = str(line.get("key", "")).strip()
        text = str(line.get("text", "")).strip()
        path = str(line.get("path", "")).strip()
        notes = str(line.get("notes", "")).strip()
        if not key or not text or not path:
            continue
        normalized_lines.append({
            "key": key,
            "text": text,
            "filename": Path(path.replace("res://", "", 1)).name,
            "godot_path": path,
            "notes": notes,
        })

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["key", "filename", "text", "notes", "godot_path"],
        )
        writer.writeheader()
        for line in normalized_lines:
            writer.writerow(line)

    txt_path.write_text(_make_text_script(catalog, normalized_lines), encoding="utf-8")

    print(f"Exported {len(normalized_lines)} recording lines.")
    print(f"CSV: {csv_path}")
    print(f"Text: {txt_path}")
    return 0


def _make_text_script(catalog: dict, lines: list[dict]) -> str:
    voice = catalog.get("voice", {})
    instructions = str(voice.get("instructions", "")).strip()
    sections = [
        "Farm Chore Friends Voice-Over Recording Script",
        "",
        "Voice direction:",
        instructions or "Use the same calm adult woman voice for every line.",
        "",
        "Recording notes:",
        "- Record one female speaker in one quiet session when possible.",
        "- Keep delivery warm, gentle, clear, and reassuring.",
        "- Leave clean silence at the start and end of each take.",
        "- Export each accepted take as WAV using the listed filename.",
        "- Do not change the line text unless the catalog is updated too.",
        "",
        "Lines:",
        "",
    ]
    for index, line in enumerate(lines, start=1):
        sections.extend([
            f"{index:02d}. {line['key']}",
            f"Filename: {line['filename']}",
            f"Text: {line['text']}",
            f"Notes: {line['notes']}",
            "",
        ])
    return "\n".join(sections)


def _resolve_project_path(project_root: Path, path_text: str) -> Path:
    if path_text.startswith("res://"):
        return project_root / path_text.replace("res://", "", 1)
    path = Path(path_text)
    if path.is_absolute():
        return path
    return project_root / path


if __name__ == "__main__":
    raise SystemExit(main())
