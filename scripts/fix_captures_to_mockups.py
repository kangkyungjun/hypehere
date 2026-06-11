#!/usr/bin/env python3
"""
Replace Apple/Google captures with mockup-based images.

Apple captures (6.5/ 6.7/):
  - Delete existing PNG (resized raw screenshot)
  - Take v3_mockups/{stem}-portrait.png (1419x2796 RGBA)
  - Resize to target size, save as RGBA PNG

Google captures:
  - Delete existing JPG (raw screenshot)
  - Copy v3_mockups/{stem}-portrait.png as PNG into same folder

Usage:
    python scripts/fix_captures_to_mockups.py
"""

import sys
from pathlib import Path

from PIL import Image

BASE_DIR = Path("assets/screenshots")
MOCKUP_DIR = BASE_DIR / "v3_mockups"
V3_DIR = BASE_DIR / "v3"

APPLE_SIZES = {
    "6.5": (1242, 2688),
    "6.7": (1290, 2796),
}

LANGUAGES = ["ko", "en", "zh", "ja", "es"]


def main():
    if not MOCKUP_DIR.is_dir():
        print(f"Error: mockup directory not found: {MOCKUP_DIR}")
        sys.exit(1)

    mockup_files = {f.stem: f for f in MOCKUP_DIR.glob("*.png")}
    print(f"Found {len(mockup_files)} mockup files in {MOCKUP_DIR}")

    apple_replaced = 0
    google_replaced = 0

    for lang in LANGUAGES:
        # --- Apple captures ---
        for size_name, (w, h) in APPLE_SIZES.items():
            cap_dir = V3_DIR / "apple" / lang / "captures" / size_name
            if not cap_dir.is_dir():
                print(f"  Warning: directory not found: {cap_dir}")
                continue

            existing = list(cap_dir.glob("*.png"))
            for old_file in existing:
                # Derive stem: Screenshot_..._MarketLens-portrait -> Screenshot_..._MarketLens-portrait
                stem = old_file.stem  # e.g. Screenshot_20260528_203602_MarketLens-portrait
                mockup_src = mockup_files.get(stem)
                if mockup_src is None:
                    print(f"  Warning: no mockup for {stem}")
                    continue

                # Delete old file
                old_file.unlink()

                # Resize mockup to target size and save
                img = Image.open(mockup_src)
                img = img.resize((w, h), Image.LANCZOS)
                img.save(old_file, "PNG")
                apple_replaced += 1

            print(f"  apple/{lang}/captures/{size_name}: {len(existing)} files replaced")

        # --- Google captures ---
        google_dir = V3_DIR / "google" / lang / "captures"
        if not google_dir.is_dir():
            print(f"  Warning: directory not found: {google_dir}")
            continue

        existing_jpgs = list(google_dir.glob("*.jpg"))
        for old_jpg in existing_jpgs:
            # Derive mockup stem: Screenshot_..._MarketLens -> Screenshot_..._MarketLens-portrait
            stem = old_jpg.stem + "-portrait"
            mockup_src = mockup_files.get(stem)
            if mockup_src is None:
                print(f"  Warning: no mockup for {stem}")
                continue

            # Delete old JPG
            old_jpg.unlink()

            # Copy mockup PNG to same folder (keep original mockup size)
            dst = google_dir / f"{old_jpg.stem}.png"
            img = Image.open(mockup_src)
            img.save(dst, "PNG")
            google_replaced += 1

        print(f"  google/{lang}/captures: {len(existing_jpgs)} JPGs replaced with PNGs")

    print(f"\nDone. Replaced {apple_replaced} Apple captures + {google_replaced} Google captures")

    # --- Verification ---
    print("\n--- Verification ---")
    for lang in LANGUAGES:
        for size_name, (w, h) in APPLE_SIZES.items():
            cap_dir = V3_DIR / "apple" / lang / "captures" / size_name
            pngs = list(cap_dir.glob("*.png"))
            if pngs:
                sample = Image.open(pngs[0])
                alpha = sample.split()[3] if sample.mode == "RGBA" else None
                has_transparency = alpha and alpha.getextrema()[0] == 0
                status = "OK" if (sample.size == (w, h)
                                  and sample.mode == "RGBA"
                                  and has_transparency) else "FAIL"
                print(f"  apple/{lang}/{size_name}: {len(pngs)} files, "
                      f"{sample.size} {sample.mode}, "
                      f"transparency={has_transparency} [{status}]")

        google_dir = V3_DIR / "google" / lang / "captures"
        pngs = list(google_dir.glob("*.png"))
        jpgs = list(google_dir.glob("*.jpg"))
        if pngs:
            sample = Image.open(pngs[0])
            print(f"  google/{lang}: {len(pngs)} PNGs ({sample.size} {sample.mode}), "
                  f"{len(jpgs)} JPGs remaining")
        else:
            print(f"  google/{lang}: {len(pngs)} PNGs, {len(jpgs)} JPGs [FAIL - no PNGs]")


if __name__ == "__main__":
    main()
