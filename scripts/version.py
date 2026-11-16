#!/usr/bin/env python3
"""Choose the next Food Guardian Forever beta version or stamp its manifest."""
from pathlib import Path
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "addon" / "FoodGuardian.toc"
PREFIX = "forever-"
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+b[1-9][0-9]*$")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).splitlines()


def current_version():
    if not TOC.is_file():
        raise FileNotFoundError("No addon TOC yet. Implement the addon before releasing.")
    match = re.search(r"^## Version: (.+?)\s*$", TOC.read_text(encoding="utf-8-sig"), re.M)
    if not match or not VERSION_RE.fullmatch(match.group(1)):
        raise ValueError("The TOC needs a beta version such as 1.0b1")
    return match.group(1)


def select():
    ref = os.environ.get("GITHUB_REF", "")
    if ref.startswith("refs/tags/"):
        tag = ref.removeprefix("refs/tags/")
        if not tag.startswith(PREFIX) or not VERSION_RE.fullmatch(tag.removeprefix(PREFIX)):
            raise ValueError(f"Invalid release tag: {tag}")
        return tag.removeprefix(PREFIX)
    initial = current_version()
    series = initial.split("b", 1)[0]
    pattern = re.compile(rf"^{PREFIX}{re.escape(series)}b([1-9][0-9]*)$")
    tags = git("tag", "--list", f"{PREFIX}{series}b*")
    current_commit = set(git("tag", "--points-at", "HEAD"))
    numbered = {tag: int(match.group(1)) for tag in tags if (match := pattern.fullmatch(tag))}
    at_head = [value for tag, value in numbered.items() if tag in current_commit]
    number = max(at_head) if at_head else max(numbered.values(), default=0) + 1
    return f"{series}b{number}"


def stamp(version):
    if not VERSION_RE.fullmatch(version):
        raise ValueError(f"Invalid beta version: {version}")
    source = TOC.read_text(encoding="utf-8")
    output, count = re.subn(r"^## Version: .+$", f"## Version: {version}", source, flags=re.M)
    if count != 1:
        raise ValueError("Expected exactly one TOC version field")
    TOC.write_text(output, encoding="utf-8")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["select"]:
            print(select())
        elif len(sys.argv) == 3 and sys.argv[1] == "stamp":
            stamp(sys.argv[2])
        else:
            sys.exit("Usage: version.py select | stamp VERSION")
    except (ValueError, FileNotFoundError) as error:
        sys.exit(str(error))
