#!/usr/bin/env python3
"""Check lightweight Android release-readiness settings for local QA."""

from __future__ import annotations

import argparse
import configparser
import re
from pathlib import Path


EXPECTED_FALSE_PERMISSIONS = (
    "permissions/internet",
    "permissions/camera",
    "permissions/record_audio",
    "permissions/access_fine_location",
    "permissions/read_contacts",
)


def read_project_settings(path: Path) -> dict[str, str]:
	values: dict[str, str] = {}
	if not path.exists():
		return values
	section = ""
	for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
		line = raw_line.strip()
		if not line:
			continue
		if line.startswith("[") and line.endswith("]"):
			section = line.strip("[]")
			continue
		if "=" not in line:
			continue
		key, value = line.split("=", 1)
		clean_key = key.strip()
		if section:
			clean_key = f"{section}/{clean_key}"
		values[clean_key] = value.strip().strip('"')
	return values


def read_export_preset(path: Path) -> dict[str, str]:
    parser = configparser.ConfigParser(strict=False)
    parser.optionxform = str
    if not path.exists():
        return {}
    parser.read(path, encoding="utf-8")
    if "preset.0.options" not in parser:
        return {}
    return dict(parser["preset.0.options"])


def read_export_root(path: Path) -> dict[str, str]:
	parser = configparser.ConfigParser(strict=False)
	parser.optionxform = str
	if not path.exists():
		return {}
	parser.read(path, encoding="utf-8")
	if "preset.0" not in parser:
		return {}
	return dict(parser["preset.0"])


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Android release-readiness settings.")
    parser.add_argument("--root", default=".", help="Project root.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    project = read_project_settings(root / "project.godot")
    preset_path = root / "export_presets.cfg"
    export_root = read_export_root(preset_path)
    export_options = read_export_preset(preset_path)
    failures: list[str] = []
    notes: list[str] = []

    if project.get("display/window/handheld/orientation") != "landscape":
        failures.append("Project orientation should be landscape.")
    if project.get("display/window/stretch/aspect") != "expand":
        failures.append("Stretch aspect should stay set to expand.")
    if project.get("display/window/stretch/mode") != "canvas_items":
        failures.append("Stretch mode should stay set to canvas_items.")

    package_name = export_options.get("package/unique_name", "").strip('"')
    app_name = export_options.get("package/name", "").strip('"')
    project_name = project.get("application/config/name", "")
    assembly_name = project.get("dotnet/project/assembly_name", "")
    version_name = export_options.get("version/name", "").strip('"')
    export_path = export_root.get("export_path", "").strip('"')
    if not package_name or package_name.startswith("org.godotengine"):
        failures.append("Android package/unique_name must be app-specific.")
    if not app_name:
        failures.append("Android package/name must be set.")
    if app_name and project_name and app_name != project_name:
        notes.append("Android package/name does not match project config/name.")
    if app_name and assembly_name and app_name != assembly_name:
        notes.append("Android package/name does not match dotnet assembly_name.")
    if version_name:
        match = re.search(r"-v(\d+\.\d+\.\d+)-release-signed\.aab$", export_path)
        if match is None:
            failures.append("Android export_path should end with -v<version/name>-release-signed.aab.")
        elif match.group(1) != version_name:
            failures.append("Android export_path version does not match version/name.")
    else:
        failures.append("Android version/name must be set.")
    version_code = export_options.get("version/code", "0")
    try:
        if int(version_code) <= 0:
            failures.append("Android version/code must be greater than 0.")
    except ValueError:
        failures.append("Android version/code must be numeric.")
    if export_options.get("screen/immersive_mode") != "true":
        notes.append("screen/immersive_mode is not true; confirm this is intentional.")
    if export_options.get("architectures/arm64-v8a") != "true":
        failures.append("ARM64 Android export should be enabled.")
    for permission in EXPECTED_FALSE_PERMISSIONS:
        if export_options.get(permission) != "false":
            failures.append("%s should be false for the toddler game." % permission)

    print("Release Readiness Check")
    print("=======================")
    print("Root: %s" % root)
    print("Package: %s" % (package_name if package_name else "missing"))
    print("App name: %s" % (app_name if app_name else "missing"))
    print("Version name: %s" % (version_name if version_name else "missing"))
    print("Version code: %s" % version_code)
    print("Export path: %s" % (export_path if export_path else "missing"))
    print()
    if notes:
        print("Notes:")
        for note in notes:
            print("- %s" % note)
        print()
    if failures:
        print("Failures:")
        for failure in failures:
            print("- %s" % failure)
        return 1
    print("Release readiness settings look OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
