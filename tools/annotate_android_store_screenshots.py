#!/usr/bin/env python3
"""Add friendly caption banners to the Android store screenshot set."""

from __future__ import annotations

import argparse
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CAPTIONS = {
    "01_start_screen.png": {
        "text": "Tap to start the farm fun!",
        "box": (510, 312, 1410, 430),
    },
    "02_farmyard_overview.png": {
        "text": "Five cheerful chores, one happy farm!",
        "box": (450, 148, 1470, 256),
    },
    "03_egg_hunt.png": {
        "text": "Egg hunt time! Fill the basket!",
        "box": (550, 918, 1370, 1018),
    },
    "04_milking_time.png": {
        "text": "Help the cow and fill the bucket!",
        "box": (600, 42, 1320, 142),
    },
    "05_garden_care.png": {
        "text": "Plant, water, grow, harvest!",
        "box": (610, 42, 1310, 142),
    },
    "06_feeding_friends.png": {
        "text": "Feed the animals and hear happy munches!",
        "box": (450, 42, 1470, 150),
    },
    "07_brushing_barn.png": {
        "text": "Brush the barn friends until they shine!",
        "box": (480, 42, 1440, 150),
    },
    "08_duck_pond.png": {
        "text": "Tap the lily pads and make ducky music!",
        "box": (420, 42, 1500, 150),
    },
    "09_mole_game.png": {
        "text": "Catch the happy mole before it pops away!",
        "box": (420, 42, 1500, 150),
    },
}


def load_font(size: int) -> ImageFont.ImageFont:
    for name in ("arial.ttf", "DejaVuSans-Bold.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_caption(image: Image.Image, text: str, box: tuple[int, int, int, int]) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    x1, y1, x2, y2 = box
    pad_x = 26
    pad_y = 18
    inner_width = max(240, x2 - x1 - pad_x * 2)
    font_size = 58 if image.width >= 1800 else 48
    font = load_font(font_size)

    wrapped = _wrap_text(text, font, inner_width, draw)
    bbox = draw.multiline_textbbox((0, 0), wrapped, font=font, spacing=10, align="center")
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    banner_w = min(image.width - 80, max(text_w + pad_x * 2, 560))
    banner_h = min(image.height - 80, max(text_h + pad_y * 2, 96))
    bx1 = x1 + max(0, (x2 - x1 - banner_w) // 2)
    by1 = y1 + max(0, (y2 - y1 - banner_h) // 2)
    bx2 = bx1 + banner_w
    by2 = by1 + banner_h

    draw.rounded_rectangle(
        (bx1, by1, bx2, by2),
        radius=34,
        fill=(255, 247, 220, 228),
        outline=(131, 84, 44, 255),
        width=6,
    )
    shadow_box = (bx1 + 6, by1 + 8, bx2 + 6, by2 + 8)
    draw.rounded_rectangle(
        shadow_box,
        radius=34,
        fill=(0, 0, 0, 35),
    )
    draw.rounded_rectangle(
        (bx1, by1, bx2, by2),
        radius=34,
        fill=(255, 247, 220, 228),
        outline=(131, 84, 44, 255),
        width=6,
    )
    text_x = bx1 + banner_w // 2
    text_y = by1 + banner_h // 2
    draw.multiline_text(
        (text_x, text_y),
        wrapped,
        font=font,
        fill=(92, 54, 30, 255),
        spacing=10,
        align="center",
        anchor="mm",
    )

    return Image.alpha_composite(image, overlay)


def _wrap_text(text: str, font: ImageFont.ImageFont, max_width: int, draw: ImageDraw.ImageDraw) -> str:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        candidate = " ".join(current + [word])
        bbox = draw.textbbox((0, 0), candidate, font=font)
        if bbox[2] - bbox[0] <= max_width or not current:
            current.append(word)
            continue
        lines.append(" ".join(current))
        current = [word]
    if current:
        lines.append(" ".join(current))
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Annotate Android store screenshots with friendly captions.")
    parser.add_argument("--root", default=".", help="Project root.")
    parser.add_argument(
        "--input-dir",
        default="_qa_previews/android_store_screenshots",
        help="Source screenshot directory, relative to root unless absolute.",
    )
    parser.add_argument(
        "--output-dir",
        default="_qa_previews/android_store_screenshots_captioned",
        help="Captioned output directory, relative to root unless absolute.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    input_dir = Path(args.input_dir)
    if not input_dir.is_absolute():
        input_dir = root / input_dir
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = root / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    for name, meta in CAPTIONS.items():
        source = input_dir / name
        if not source.exists():
            print(f"Skipping missing {source}")
            continue
        image = Image.open(source).convert("RGBA")
        annotated = draw_caption(image, str(meta["text"]), tuple(meta["box"]))
        annotated.convert("RGB").save(output_dir / name, quality=95)
        print(f"Wrote {output_dir / name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
