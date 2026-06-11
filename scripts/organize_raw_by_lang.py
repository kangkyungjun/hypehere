#!/usr/bin/env python3
"""
Organize flat v3_raw/ and v3_mockups/ files into language subfolders.

Moves files from:
    assets/screenshots/v3_raw/*.jpg       -> v3_raw/{lang}/*.jpg
    assets/screenshots/v3_mockups/*.png   -> v3_mockups/{lang}/*.png

Uses timestamp ranges to determine language assignment.

Usage:
    python scripts/organize_raw_by_lang.py
"""

import re
import shutil
import sys
from pathlib import Path

BASE_DIR = Path("assets/screenshots")
RAW_DIR = BASE_DIR / "v3_raw"
MOCKUP_DIR = BASE_DIR / "v3_mockups"

# Language groups by timestamp ranges (HHMMSS)
LANG_RANGES = [
    ("ko", "203241", "203523", 9),
    ("en", "203602", "203659", 9),
    ("zh", "203714", "203756", 9),
    ("ja", "203808", "203859", 10),
    ("es", "203911", "203958", 10),
]

TS_PATTERN = re.compile(r"Screenshot_\d{8}_(\d{6})_MarketLens")


def detect_lang(filename: str) -> str | None:
    m = TS_PATTERN.search(filename)
    if not m:
        return None
    ts = m.group(1)
    for lang, start, end, _ in LANG_RANGES:
        if start <= ts <= end:
            return lang
    return None


def organize_dir(src_dir: Path, ext: str):
    """Move files from flat src_dir into src_dir/{lang}/ subfolders."""
    files = sorted(src_dir.glob(f"*.{ext}"))
    if not files:
        print(f"  No *.{ext} files found in {src_dir}")
        return 0

    # Skip if already organized (files exist in subfolders)
    top_level_files = [f for f in files if f.parent == src_dir]
    if not top_level_files:
        print(f"  {src_dir}: already organized (no top-level files)")
        return 0

    moved = 0
    for f in top_level_files:
        lang = detect_lang(f.name)
        if lang is None:
            print(f"  Warning: cannot classify {f.name}")
            continue
        dest_dir = src_dir / lang
        dest_dir.mkdir(exist_ok=True)
        dest = dest_dir / f.name
        shutil.move(str(f), str(dest))
        moved += 1

    return moved


def main():
    if not RAW_DIR.is_dir():
        print(f"Error: {RAW_DIR} not found")
        sys.exit(1)
    if not MOCKUP_DIR.is_dir():
        print(f"Error: {MOCKUP_DIR} not found")
        sys.exit(1)

    print("=== Organizing v3_raw ===")
    raw_moved = organize_dir(RAW_DIR, "jpg")
    print(f"  Moved {raw_moved} raw files")

    print("\n=== Organizing v3_mockups ===")
    mockup_moved = organize_dir(MOCKUP_DIR, "png")
    print(f"  Moved {mockup_moved} mockup files")

    # Verification
    print("\n--- Verification ---")
    for lang, _, _, expected in LANG_RANGES:
        raw_count = len(list((RAW_DIR / lang).glob("*.jpg"))) if (RAW_DIR / lang).is_dir() else 0
        mock_count = len(list((MOCKUP_DIR / lang).glob("*.png"))) if (MOCKUP_DIR / lang).is_dir() else 0
        status = "OK" if raw_count == expected and mock_count == expected else "MISMATCH"
        print(f"  {lang}: raw={raw_count}, mockups={mock_count}, expected={expected} [{status}]")

    print(f"\nDone. Total moved: {raw_moved} raw + {mockup_moved} mockups")


if __name__ == "__main__":
    main()
