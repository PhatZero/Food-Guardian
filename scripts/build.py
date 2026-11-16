#!/usr/bin/env python3
"""Validate and package the future WoW Forever Food Guardian addon."""
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon"
TOC = ADDON / "FoodGuardian.toc"
DIST = ROOT / "dist"
SUPPORTED = {".toc", ".lua", ".xml", ".tga", ".blp", ".ttf", ".otf"}
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+b[1-9][0-9]*$")


def manifest_value(text: str, field: str) -> str:
    found = re.findall(rf"^## {re.escape(field)}: (.+?)\s*$", text, re.M)
    if len(found) != 1:
        raise ValueError(f"Expected exactly one {field} field")
    return found[0].strip()


def validate_manifest(addon: Path = ADDON):
    toc = addon / "FoodGuardian.toc"
    if not toc.is_file():
        raise FileNotFoundError(
            "The addon has not been implemented yet: addon/FoodGuardian.toc is missing."
        )
    contents = toc.read_text(encoding="utf-8-sig")
    if manifest_value(contents, "Interface") != "16001":
        raise ValueError("Expected WoW Forever 1.60.1 interface 16001")
    version = manifest_value(contents, "Version")
    if not VERSION_RE.fullmatch(version):
        raise ValueError(f"Expected a beta version such as 1.0b1; got {version!r}")
    entries = []
    for line in contents.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        item = PurePosixPath(line.replace("\\", "/"))
        if item.is_absolute() or not item.parts or ".." in item.parts:
            raise ValueError(f"Unsafe manifest entry: {line}")
        if item.suffix.lower() not in {".lua", ".xml"}:
            raise ValueError(f"Unrecognized TOC entry: {line}")
        if not (addon / Path(*item.parts)).is_file():
            raise ValueError(f"Missing TOC file: {line}")
        entries.append(item.as_posix())
    if not entries or len(entries) != len(set(entries)):
        raise ValueError("TOC must list unique Lua/XML files")
    if not any(entry.endswith(".lua") for entry in entries):
        raise ValueError("At least one Lua file must be listed by the TOC")

    relative_files = []
    for source in sorted(addon.rglob("*")):
        if source.is_symlink():
            raise ValueError(f"Symlinks are not allowed in addon packages: {source}")
        if not source.is_file():
            continue
        relative = source.relative_to(addon)
        if source.suffix.lower() not in SUPPORTED:
            raise ValueError(f"Unsupported addon file: {relative}")
        relative_files.append(relative)
    return version, relative_files


def build(addon: Path = ADDON, dist: Path = DIST) -> Path:
    version, files = validate_manifest(addon)
    dist.mkdir(parents=True, exist_ok=True)
    target = dist / f"FoodGuardian-Forever-{version}.zip"
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in files:
            archive.write(addon / relative, (PurePosixPath("FoodGuardian") / relative.as_posix()).as_posix())
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None, "Archive integrity failed"
        assert "FoodGuardian/FoodGuardian.toc" in archive.namelist()
    return target


if __name__ == "__main__":
    try:
        print("Built:", build())
    except (ValueError, FileNotFoundError, AssertionError) as error:
        sys.exit(str(error))
