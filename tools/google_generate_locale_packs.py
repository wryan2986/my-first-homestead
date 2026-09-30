#!/usr/bin/env python3
"""Generate locale voice packs with Google Cloud TTS."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate shipped locale voice packs with Google TTS.")
    parser.add_argument("--project-root", default=".", help="Godot project root.")
    parser.add_argument("--locale", default="", help="Generate one locale pack, such as es or pt-BR.")
    parser.add_argument("--all-locales", action="store_true", help="Generate every shipped locale except English.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned files without writing anything.")
    parser.add_argument("--force", action="store_true", help="Regenerate files that already exist.")
    parser.add_argument("--only", action="append", default=[], help="Generate one key. Can be passed multiple times.")
    parser.add_argument("--voice", default="", help="Override Google voice family.")
    parser.add_argument("--speaking-rate", type=float, default=0.92, help="Google TTS speaking rate.")
    parser.add_argument("--response-format", default="ogg", help="Audio format to write, usually ogg.")
    parser.add_argument("--pause", type=float, default=0.15, help="Pause between generated clips in seconds.")
    parser.add_argument(
        "--voice-prompt-root",
        default="localization/voice_prompts",
        help="Root folder containing translated voice prompt catalogs.",
    )
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    script_path = project_root / "tools" / "generate_voice_over.py"
    if not script_path.exists():
        print(f"Missing generator: {script_path}", file=sys.stderr)
        return 1

    command = [
        sys.executable,
        str(script_path),
        "--project-root",
        str(project_root),
        "--provider",
        "google",
        "--speaking-rate",
        str(args.speaking_rate),
        "--response-format",
        args.response_format,
        "--pause",
        str(args.pause),
        "--voice-prompt-root",
        str((project_root / args.voice_prompt_root).resolve()),
    ]
    if args.locale:
        command.extend(["--locale", args.locale])
    if args.all_locales:
        command.append("--all-locales")
    if args.dry_run:
        command.append("--dry-run")
    if args.force:
        command.append("--force")
    for key in args.only:
        command.extend(["--only", key])
    if args.voice:
        command.extend(["--voice", args.voice])

    return subprocess.run(command, cwd=project_root).returncode


if __name__ == "__main__":
    raise SystemExit(main())
