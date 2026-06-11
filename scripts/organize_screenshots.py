#!/usr/bin/env python3
"""
Organize v3 raw screenshots and mockups into Apple/Google submission folders.

Assigns 47 screenshots to 5 language groups by visually-verified timestamp
ranges, then creates the folder structure matching v1 layout.

Captures are generated as marketing screenshots (gradient background + badge +
title + subtitle + phone mockup) via create_store_screenshots.py. This script
handles mockup copying and orchestrates the full pipeline.

Usage:
    python scripts/organize_screenshots.py
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BASE_DIR = Path("assets/screenshots")
RAW_DIR = BASE_DIR / "v3_raw"
MOCKUP_DIR = BASE_DIR / "v3_mockups"
OUT_DIR = BASE_DIR / "v3"

# Language groups defined by visually-verified timestamp ranges (HHMMSS)
# Each entry: (lang_code, start_ts, end_ts, expected_count)
LANG_RANGES = [
    ("ko", "203241", "203523", 9),
    ("en", "203602", "203659", 9),
    ("zh", "203714", "203756", 9),
    ("ja", "203808", "203859", 10),
    ("es", "203911", "203958", 10),
]

LANG_ORDER = [lang for lang, *_ in LANG_RANGES]

# Apple capture target sizes
APPLE_SIZES = {
    "6.5": (1242, 2688),
    "6.7": (1290, 2796),
}

# Timestamp regex: Screenshot_YYYYMMDD_HHMMSS_MarketLens
TS_PATTERN = re.compile(r"Screenshot_\d{8}_(\d{6})_MarketLens")



def extract_hhmmss(filename):
    """Extract HHMMSS timestamp string from filename."""
    m = TS_PATTERN.search(filename)
    return m.group(1) if m else None


def group_by_language(files):
    """Assign files to language groups by timestamp range."""
    lang_map = {lang: [] for lang in LANG_ORDER}

    for f in files:
        ts = extract_hhmmss(f.name)
        if ts is None:
            print(f"  Warning: cannot parse timestamp from {f.name}")
            continue
        assigned = False
        for lang, start, end, _ in LANG_RANGES:
            if start <= ts <= end:
                lang_map[lang].append(f)
                assigned = True
                break
        if not assigned:
            print(f"  Warning: {f.name} (ts={ts}) doesn't match any language range")

    return lang_map


def main():
    if not RAW_DIR.is_dir():
        print(f"Error: raw directory not found: {RAW_DIR}")
        sys.exit(1)
    if not MOCKUP_DIR.is_dir():
        print(f"Error: mockup directory not found: {MOCKUP_DIR}")
        sys.exit(1)

    # Support both flat and organized (lang subfolder) layouts
    raw_files = sorted(RAW_DIR.glob("*.jpg"))
    if not raw_files:
        raw_files = sorted(RAW_DIR.glob("*/*.jpg"))
    print(f"Found {len(raw_files)} raw screenshots")

    # Group by timestamp range
    lang_map = group_by_language(raw_files)

    # Verify counts
    ok = True
    for lang, start, end, expected in LANG_RANGES:
        actual = len(lang_map[lang])
        status = "OK" if actual == expected else "MISMATCH"
        if actual != expected:
            ok = False
        files = lang_map[lang]
        if files:
            print(f"  {lang}: {actual}/{expected} files "
                  f"({files[0].name} - {files[-1].name}) [{status}]")
        else:
            print(f"  {lang}: 0/{expected} files [EMPTY]")
    if not ok:
        print("Error: file count mismatch")
        sys.exit(1)
    print()

    # Step 1: Generate marketing screenshots (captures) via create_store_screenshots.py
    print("=== Generating marketing screenshots ===")
    store_script = Path("scripts/create_store_screenshots.py")
    if not store_script.exists():
        print(f"Error: {store_script} not found")
        sys.exit(1)
    result = subprocess.run(
        [sys.executable, str(store_script)],
        capture_output=False,
    )
    if result.returncode != 0:
        print("Error: create_store_screenshots.py failed")
        sys.exit(1)
    print()

    # Step 2: Copy mockups into organized folders
    print("=== Copying mockups ===")
    total_mockups = 0
    for lang, files in lang_map.items():
        (OUT_DIR / "apple" / lang / "mockups").mkdir(parents=True, exist_ok=True)

        # Mockup dir: try lang subfolder first, then flat
        lang_mockup_dir = MOCKUP_DIR / lang
        if not lang_mockup_dir.is_dir():
            lang_mockup_dir = MOCKUP_DIR

        for raw_file in files:
            stem = raw_file.stem
            mockup_src = lang_mockup_dir / f"{stem}-portrait.png"

            if not mockup_src.exists():
                print(f"  Warning: mockup not found: {mockup_src}")
                continue

            mockup_dst = OUT_DIR / "apple" / lang / "mockups" / f"{stem}-portrait.png"
            shutil.copy2(mockup_src, mockup_dst)
            total_mockups += 1

        print(f"  {lang}: {len(files)} mockups copied")

    print(f"\nDone. Organized {total_mockups} mockups + marketing captures into {OUT_DIR}")

    # Verification
    print("\n--- Verification ---")
    for lang in LANG_ORDER:
        for size_name, (w, h) in APPLE_SIZES.items():
            cap_dir = OUT_DIR / "apple" / lang / "captures" / size_name
            pngs = list(cap_dir.glob("*.png"))
            if pngs:
                sample = Image.open(pngs[0])
                ok_str = ("OK" if sample.size == (w, h)
                          else f"MISMATCH size={sample.size}")
                print(f"  apple/{lang}/captures/{size_name}: {len(pngs)} files, "
                      f"{sample.size} {sample.mode} [{ok_str}]")

        mockup_dir = OUT_DIR / "apple" / lang / "mockups"
        mockups = list(mockup_dir.glob("*.png"))
        print(f"  apple/{lang}/mockups: {len(mockups)} files")

        google_dir = OUT_DIR / "google" / lang / "captures"
        pngs = list(google_dir.glob("*.png"))
        if pngs:
            sample = Image.open(pngs[0])
            print(f"  google/{lang}/captures: {len(pngs)} files, "
                  f"{sample.size} {sample.mode}")
        else:
            print(f"  google/{lang}/captures: 0 files [EMPTY]")


if __name__ == "__main__":
    main()
