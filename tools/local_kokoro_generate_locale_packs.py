#!/usr/bin/env python3
"""Deprecated compatibility wrapper for the Google locale pack generator."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Deprecated wrapper for Google locale pack generation.")
    parser.add_argument("--project-root", required=True, help="Path to the Godot project root.")
    parser.add_argument("--voice", default="", help="Override Google voice family.")
    parser.add_argument("--speed", type=float, default=0.92, help="Deprecated alias for speaking rate.")
    parser.add_argument("--force", action="store_true", help="Regenerate existing files.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned files without writing anything.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    script_path = project_root / "tools" / "google_generate_locale_packs.py"
    if not script_path.exists():
        print(f"Missing Google locale generator: {script_path}", file=sys.stderr)
        return 1

    command = [
        sys.executable,
        str(script_path),
        "--project-root",
        str(project_root),
        "--all-locales",
        "--speaking-rate",
        str(args.speed),
    ]
    if args.force:
        command.append("--force")
    if args.dry_run:
        command.append("--dry-run")
    if args.voice:
        command.extend(["--voice", args.voice])

    return subprocess.run(command, cwd=project_root).returncode


if __name__ == "__main__":
    raise SystemExit(main())
