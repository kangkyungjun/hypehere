#!/usr/bin/env python3
"""
Create iPhone 15 Pro Max mockups from raw Android screenshots.
Matches the style of existing v1 mockups (1419x2796, RGBA PNG).

Usage:
    python scripts/create_mockups.py
    python scripts/create_mockups.py --input assets/screenshots/v3_raw --output assets/screenshots/v3_mockups
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------------------
# Dimensions reverse-engineered from existing v1 Apple mockups
# ---------------------------------------------------------------------------
CANVAS_W, CANVAS_H = 1419, 2796

# Phone body (outer rounded rectangle)
BODY_LEFT, BODY_TOP = 60, 61
BODY_RIGHT, BODY_BOTTOM = 1358, 2734
BODY_RADIUS = 200

# Screen area (where the screenshot is placed)
SCREEN_X, SCREEN_Y = 65, 61
SCREEN_W, SCREEN_H = 1290, 2674
SCREEN_RADIUS = 190

# Dynamic Island pill
DI_W, DI_H = 130, 40
DI_CX = CANVAS_W // 2
DI_CY = 140

# Side buttons: (y_start, y_end, protrusion_px, side)
SIDE_BUTTONS = [
    # Left side - mute switch
    (610, 710, 10, "left"),
    # Left side - volume up
    (790, 1010, 8, "left"),
    # Left side - volume down
    (1050, 1250, 8, "left"),
    # Right side - power
    (870, 1190, 7, "right"),
]

# Bezel gradient (3D edge effect) - width in pixels
BEZEL_GRADIENT_WIDTH = 10


def create_rounded_rect_mask(w, h, radius):
    """Create an anti-aliased rounded rectangle mask at 2x then downscale."""
    scale = 2
    mask_big = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask_big)
    draw.rounded_rectangle(
        [0, 0, w * scale - 1, h * scale - 1],
        radius=radius * scale,
        fill=255,
    )
    return mask_big.resize((w, h), Image.LANCZOS)


def draw_phone_body(canvas):
    """Draw the phone body, side buttons, and bezel gradient."""
    draw = ImageDraw.Draw(canvas)

    # Side buttons (drawn first, behind phone body edges)
    for y1, y2, protrusion, side in SIDE_BUTTONS:
        if side == "left":
            bx1, bx2 = BODY_LEFT - protrusion, BODY_LEFT + 2
        else:
            bx1, bx2 = BODY_RIGHT - 2, BODY_RIGHT + protrusion
        draw.rounded_rectangle(
            [bx1, y1, bx2, y2], radius=4, fill=(25, 25, 25, 255)
        )

    # Phone body - main fill
    draw.rounded_rectangle(
        [BODY_LEFT, BODY_TOP, BODY_RIGHT, BODY_BOTTOM],
        radius=BODY_RADIUS,
        fill=(10, 10, 10, 255),
    )

    # Bezel gradient (3D highlight along inner edge of body)
    for i in range(BEZEL_GRADIENT_WIDTH):
        inset = i + 1
        # Brightness ramps from dark at edge to slightly lighter inside
        brightness = 15 + int(i * 7)
        alpha = max(30, 255 - i * 25)
        r = max(1, BODY_RADIUS - inset)
        draw.rounded_rectangle(
            [
                BODY_LEFT + inset,
                BODY_TOP + inset,
                BODY_RIGHT - inset,
                BODY_BOTTOM - inset,
            ],
            radius=r,
            outline=(brightness, brightness + 2, brightness + 2, alpha),
            width=1,
        )


def draw_dynamic_island(canvas):
    """Draw the Dynamic Island pill at the top of the screen."""
    draw = ImageDraw.Draw(canvas)
    x1 = DI_CX - DI_W // 2
    y1 = DI_CY - DI_H // 2
    x2 = DI_CX + DI_W // 2
    y2 = DI_CY + DI_H // 2
    draw.rounded_rectangle([x1, y1, x2, y2], radius=DI_H // 2, fill=(0, 0, 0, 255))


def create_screen_shadow(w, h, radius, shadow_width=8):
    """Create a subtle inner shadow overlay for the screen edges."""
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)

    for i in range(shadow_width):
        alpha = int(60 * (1 - i / shadow_width))
        r = max(1, radius - i)
        draw.rounded_rectangle(
            [i, i, w - 1 - i, h - 1 - i],
            radius=r,
            outline=(0, 0, 0, alpha),
            width=1,
        )
    return shadow


def prepare_screenshot(path, target_w, target_h):
    """Resize a screenshot to fill the target dimensions exactly.

    Uses direct stretch-to-fit. The aspect ratio difference between
    Android (1080x2124, ratio 0.509) and iPhone screen (1290x2674,
    ratio 0.483) is ~5% vertical, which is imperceptible on UI content
    and avoids cropping any screen edges.
    """
    img = Image.open(path).convert("RGB")
    return img.resize((target_w, target_h), Image.LANCZOS)


def create_mockup(screenshot_path, output_path):
    """Create a single iPhone mockup from a raw screenshot."""
    # 1. Transparent canvas
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))

    # 2. Phone body + bezel gradient + side buttons
    draw_phone_body(canvas)

    # 3. Prepare screenshot (resize + crop to screen dimensions)
    screenshot = prepare_screenshot(screenshot_path, SCREEN_W, SCREEN_H)

    # 4. Apply rounded-corner mask to screenshot
    mask = create_rounded_rect_mask(SCREEN_W, SCREEN_H, SCREEN_RADIUS)
    screen_rgba = screenshot.convert("RGBA")
    screen_rgba.putalpha(mask)

    # 5. Create screen layer and paste
    screen_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    screen_layer.paste(screen_rgba, (SCREEN_X, SCREEN_Y))

    # 6. Composite screen on top of phone body
    result = Image.alpha_composite(canvas, screen_layer)

    # 7. Inner shadow on screen edges for depth
    shadow = create_screen_shadow(SCREEN_W, SCREEN_H, SCREEN_RADIUS)
    shadow_layer = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    shadow_layer.paste(shadow, (SCREEN_X, SCREEN_Y))
    result = Image.alpha_composite(result, shadow_layer)

    # 8. Dynamic Island on top
    draw_dynamic_island(result)

    # 9. Save
    result.save(output_path, "PNG")


def main():
    parser = argparse.ArgumentParser(description="Create iPhone mockups from screenshots")
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("assets/screenshots/v3_raw"),
        help="Directory containing raw JPG screenshots",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/screenshots/v3_mockups"),
        help="Directory for output mockup PNGs",
    )
    args = parser.parse_args()

    if not args.input.is_dir():
        print(f"Error: input directory not found: {args.input}")
        sys.exit(1)

    args.output.mkdir(parents=True, exist_ok=True)

    screenshots = sorted(args.input.glob("*.jpg"))
    if not screenshots:
        print(f"No JPG files found in {args.input}")
        sys.exit(1)

    print(f"Processing {len(screenshots)} screenshots")
    print(f"  Input:  {args.input}")
    print(f"  Output: {args.output}")
    print()

    for i, src in enumerate(screenshots, 1):
        out_name = src.stem + "-portrait.png"
        out_path = args.output / out_name
        print(f"  [{i}/{len(screenshots)}] {src.name}")
        create_mockup(src, out_path)

    print(f"\nDone. {len(screenshots)} mockups saved to {args.output}")


if __name__ == "__main__":
    main()
