#!/usr/bin/env python3
"""Bump Android release version metadata in Godot export files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


EXPORT_PATH_RE = re.compile(r'export_path="([^"]*?)-v(\d+\.\d+\.\d+)-release-signed\.aab"')
VERSION_NAME_RE = re.compile(r'version/name="(\d+\.\d+\.\d+)"')
VERSION_CODE_RE = re.compile(r"version/code=(\d+)")
PACKAGE_NAME_RE = re.compile(r'package/name="([^"]+)"')
PROJECT_NAME_RE = re.compile(r'config/name="([^"]+)"')
ASSEMBLY_NAME_RE = re.compile(r'project/assembly_name="([^"]+)"')


def increment_patch(version_name: str) -> str:
	parts = version_name.split(".")
	if len(parts) != 3:
		raise ValueError("Expected semantic version in MAJOR.MINOR.PATCH format.")
	major, minor, patch = (int(part) for part in parts)
	return f"{major}.{minor}.{patch + 1}"


def replace_required(pattern: re.Pattern[str], text: str, replacement: str, label: str) -> str:
	new_text, count = pattern.subn(replacement, text, count=1)
	if count != 1:
		raise RuntimeError(f"Could not update {label}; expected exactly one match.")
	return new_text


def quoted(value: str) -> str:
	return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
	parser = argparse.ArgumentParser(description="Bump Android version metadata for release export.")
	parser.add_argument("--root", default=".", help="Project root.")
	parser.add_argument("--version-name", default="", help="Explicit version name, e.g. 1.1.2.")
	parser.add_argument("--version-code", type=int, default=0, help="Explicit Android version code.")
	parser.add_argument("--app-name", default="", help="Optional app display name to apply to Godot and Android metadata.")
	parser.add_argument("--dry-run", action="store_true", help="Print planned changes without writing files.")
	args = parser.parse_args()

	root = Path(args.root).resolve()
	export_path = root / "export_presets.cfg"
	project_path = root / "project.godot"
	export_text = export_path.read_text(encoding="utf-8")
	project_text = project_path.read_text(encoding="utf-8")

	version_match = VERSION_NAME_RE.search(export_text)
	code_match = VERSION_CODE_RE.search(export_text)
	path_match = EXPORT_PATH_RE.search(export_text)
	if version_match is None:
		raise RuntimeError("Could not find version/name in export_presets.cfg.")
	if code_match is None:
		raise RuntimeError("Could not find version/code in export_presets.cfg.")
	if path_match is None:
		raise RuntimeError("Could not parse export_path with MyFirstHomestead-style release filename.")

	old_version = version_match.group(1)
	old_code = int(code_match.group(1))
	new_version = args.version_name.strip() or increment_patch(old_version)
	new_code = args.version_code or old_code + 1
	if new_code <= old_code and not args.version_code:
		raise RuntimeError("Computed version code did not increase.")

	old_export_value = path_match.group(0)
	new_export_value = f'export_path="{path_match.group(1)}-v{new_version}-release-signed.aab"'

	print("Android release metadata")
	print("========================")
	print(f"Version name: {old_version} -> {new_version}")
	print(f"Version code: {old_code} -> {new_code}")
	print(f"Export path: {old_export_value} -> {new_export_value}")
	if args.app_name:
		print(f"App name: {args.app_name}")
	if args.dry_run:
		return 0

	export_text = replace_required(EXPORT_PATH_RE, export_text, new_export_value, "export_path")
	export_text = replace_required(VERSION_NAME_RE, export_text, f'version/name="{new_version}"', "version/name")
	export_text = replace_required(VERSION_CODE_RE, export_text, f"version/code={new_code}", "version/code")
	if args.app_name:
		app_name = quoted(args.app_name)
		export_text = replace_required(PACKAGE_NAME_RE, export_text, f'package/name="{app_name}"', "package/name")
		project_text = replace_required(PROJECT_NAME_RE, project_text, f'config/name="{app_name}"', "config/name")
		project_text = replace_required(ASSEMBLY_NAME_RE, project_text, f'project/assembly_name="{app_name}"', "assembly name")

	export_path.write_text(export_text, encoding="utf-8")
	project_path.write_text(project_text, encoding="utf-8")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
