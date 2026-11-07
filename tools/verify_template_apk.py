#!/usr/bin/env python3
"""Sanity-check the standalone offline reader APK produced by CI.

This checks packaging integrity only; it is not a cryptographic signature
verification and does not claim that the APK is ready for Play Store release.
"""
from __future__ import annotations

import json
import sys
import zipfile
from pathlib import Path

REQUIRED = {
    "AndroidManifest.xml",
    "classes.dex",
    "assets/flutter_assets/assets/project.json",
}


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: verify_template_apk.py <reader-template.apk>", file=sys.stderr)
        return 2
    apk = Path(sys.argv[1])
    if not apk.is_file() or apk.stat().st_size == 0:
        print(f"APK is missing or empty: {apk}", file=sys.stderr)
        return 2

    try:
        with zipfile.ZipFile(apk) as archive:
            bad_entry = archive.testzip()
            if bad_entry:
                raise ValueError(f"Corrupt ZIP entry: {bad_entry}")
            names = set(archive.namelist())
            missing = sorted(REQUIRED - names)
            if missing:
                raise ValueError("Missing required APK entries: " + ", ".join(missing))
            payload = json.loads(
                archive.read("assets/flutter_assets/assets/project.json").decode("utf-8")
            )
            if not isinstance(payload, dict) or not isinstance(payload.get("name"), str):
                raise ValueError("Embedded project.json must be a JSON object with a string name.")
            dex_files = [name for name in names if name.startswith("classes") and name.endswith(".dex")]
            if not dex_files:
                raise ValueError("No DEX bytecode found in APK.")
    except (OSError, zipfile.BadZipFile, KeyError, UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        print(f"Template APK verification failed: {exc}", file=sys.stderr)
        return 1

    print(f"Template APK package check passed: {apk} ({apk.stat().st_size} bytes)")
    print(f"Embedded project placeholder: {payload['name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
