#!/usr/bin/env python3
"""Build a standalone Android APK from an AppMaker project JSON file.

Requires a preinstalled Flutter SDK and Android SDK/Gradle dependencies already
cached locally. No network access is requested by this script.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "engine" / "flutter_template"


def run(command: list[str], cwd: Path) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Build an offline APK from AppMaker JSON.")
    parser.add_argument("--input", required=True, type=Path, help="Project JSON exported from AppMaker")
    parser.add_argument("--output", type=Path, default=Path("dist"), help="Output directory")
    parser.add_argument("--application-id", default="com.appmaker.generated.bookapp",
                        help="Android application ID, e.g. com.example.mybooks")
    args = parser.parse_args()

    if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*){1,}", args.application_id):
        parser.error("Invalid --application-id. Use a dotted Android package ID.")
    source = args.input.resolve()
    if not source.is_file():
        parser.error(f"Input JSON does not exist: {source}")
    try:
        project = json.loads(source.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        parser.error(f"Invalid UTF-8 JSON: {exc}")
    if not isinstance(project, dict) or not isinstance(project.get("name"), str):
        parser.error("JSON must be one AppMaker project object with a string 'name'.")
    books = project.get("books", [])
    if not isinstance(books, list):
        parser.error("'books' must be a list.")
    clean_books = []
    for item in books:
        if not isinstance(item, dict):
            continue
        title, body = item.get("title", ""), item.get("body", "")
        if isinstance(title, str) and isinstance(body, str):
            clean_books.append({"title": title, "body": body})
    project["books"] = clean_books
    project["name"] = project["name"][:60]

    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    work = output / "appmaker_build_workspace"
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(TEMPLATE, work)
    (work / "assets").mkdir(exist_ok=True)
    (work / "assets" / "project.json").write_text(
        json.dumps(project, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # Create the Android platform files locally, then build strictly offline.
    run(["flutter", "create", ".", "--platforms=android",
         "--org", args.application_id.rsplit(".", 1)[0],
         "--project-name", args.application_id.rsplit(".", 1)[1]], work)
    run(["flutter", "pub", "get", "--offline"], work)
    run(["flutter", "build", "apk", "--release", "--offline"], work)

    apk = work / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    if not apk.is_file():
        print("Build command finished but APK was not found.", file=sys.stderr)
        return 2
    safe_name = re.sub(r"[^a-zA-Z0-9_-]+", "_", project["name"]).strip("_") or "app"
    destination = output / f"{safe_name}.apk"
    shutil.copy2(apk, destination)
    print(f"SUCCESS: {destination}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        print(f"Build failed (exit code {exc.returncode}). Check Flutter/Android SDK setup and offline cache.", file=sys.stderr)
        raise SystemExit(exc.returncode)
