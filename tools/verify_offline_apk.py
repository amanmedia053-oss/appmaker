#!/usr/bin/env python3
"""Reject release APKs that declare Android network permissions."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

NETWORK_PERMISSIONS = (
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.ACCESS_WIFI_STATE",
)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: verify_offline_apk.py <aapt> <apk>", file=sys.stderr)
        return 2
    aapt, apk = sys.argv[1], Path(sys.argv[2])
    if not apk.is_file():
        print(f"APK not found: {apk}", file=sys.stderr)
        return 2
    result = subprocess.run(
        [aapt, "dump", "permissions", str(apk)],
        check=True,
        capture_output=True,
        text=True,
    )
    declared = [permission for permission in NETWORK_PERMISSIONS if permission in result.stdout]
    if declared:
        print("Offline APK check failed; network permissions found: " + ", ".join(declared), file=sys.stderr)
        return 1
    print(f"Offline permission check passed: {apk}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
