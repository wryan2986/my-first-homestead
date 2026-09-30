#!/usr/bin/env python3
"""Generate a simple contact sheet for mobile-readable farm assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


COW_FILES = (
    "cow_idle.png",
    "cow_happy.png",
    "cow_blinking.png",
    "cow_walking.png",
    "cow_eating.png",
    "cow_excited.png",
    "cow_celebrating.png",
)
CROP_FILES = (
    "apple_item.png",
    "carrot_item.png",
    "corn_item.png",
    "pumpkin_item.png",
    "strawberry_item.png",
    "sunflower_item.png",
    "tomato_item.png",
    "turnip_item.png",
)
PLANT_FILES = (
    "carrot.png",
    "corn.png",
    "pea.png",
    "pumpkin.png",
    "strawberry.png",
    "sunflower.png",
    "tomato.png",
    "turnip.png",
)
ANIMAL_FILES = (
    "chicken_idle.png",
    "cow_idle.png",
    "duck_idle.png",
    "goat_idle.png",
    "goose_idle.png",
    "pig_idle.png",
)
TREE_FILES = (
    "decoration_orchard_tree_spring.png",
    "decoration_orchard_tree_summer.png",
    "decoration_orchard_tree_fall.png",
    "decoration_orchard_tree_winter.png",
)
DUCK_POND_BACKGROUND_FILES = (
    "duck_pond_background_spring.png",
    "duck_pond_background_summer.png",
    "duck_pond_background_fall.png",
    "duck_pond_background_winter.png",
)
SCENE_BACKGROUND_FILES = (
    "feeding_yard_background_winter.png",
    "milking_barn_background_winter.png",
    "garden_care_background_spring.png",
    "garden_care_background_summer.png",
    "garden_care_background_fall.png",
    "garden_care_background_winter.png",
)


def load_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def paste_fit(canvas: Image.Image, path: Path, box: tuple[int, int, int, int]) -> None:
    if not path.exists():
        return
    image = Image.open(path).convert("RGBA")
    target_w = box[2] - box[0]
    target_h = box[3] - box[1]
    scale = min(target_w / image.width, target_h / image.height)
    size = (max(1, int(image.width * scale)), max(1, int(image.height * scale)))
    image = image.resize(size, Image.Resampling.LANCZOS)
    x = box[0] + (target_w - size[0]) // 2
    y = box[1] + (target_h - size[1]) // 2
    canvas.alpha_composite(image, (x, y))


def draw_label(draw: ImageDraw.ImageDraw, text: str, x: int, y: int, font: ImageFont.ImageFont) -> None:
    draw.text((x, y), text.replace("_", " ").replace(".png", ""), fill=(78, 56, 42), font=font)


def build_preview(root: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", (1600, 1120), (248, 241, 220, 255))
    draw = ImageDraw.Draw(canvas)
    title_font = load_font(34)
    label_font = load_font(20)

    draw.text((34, 24), "Cow States", fill=(64, 46, 34), font=title_font)
    for index, name in enumerate(COW_FILES):
        x = 34 + index * 218
        paste_fit(canvas, root / "art" / "animals" / name, (x, 82, x + 180, 262))
        draw_label(draw, name, x, 272, label_font)

    draw.text((34, 344), "Harvest Basket Icons", fill=(64, 46, 34), font=title_font)
    for index, name in enumerate(CROP_FILES):
        col = index % 4
        row = index // 4
        x = 66 + col * 360
        y = 420 + row * 300
        paste_fit(canvas, root / "art" / "garden" / "harvest_items" / name, (x, y, x + 210, y + 210))
        draw_label(draw, name, x, y + 224, label_font)

    canvas.convert("RGB").save(output)
    print(f"Wrote {output}")


def build_extra_preview(root: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", (1800, 1800), (248, 241, 220, 255))
    draw = ImageDraw.Draw(canvas)
    title_font = load_font(34)
    label_font = load_font(18)

    sections = [
        ("Garden Plant Assets", root / "art" / "garden", PLANT_FILES, 34, 82, 6, 260, 210),
        ("Animal Idle Sprites", root / "art" / "animals", ANIMAL_FILES, 34, 462, 6, 260, 210),
        ("Seasonal Farm Tree", root / "art" / "props", TREE_FILES, 34, 842, 4, 350, 230),
        ("Duck Pond Backgrounds", root / "art" / "backgrounds", DUCK_POND_BACKGROUND_FILES, 34, 1240, 4, 390, 180),
    ]

    for title, folder, names, start_x, start_y, columns, step_x, image_size in sections:
        draw.text((start_x, start_y - 58), title, fill=(64, 46, 34), font=title_font)
        for index, name in enumerate(names):
            col = index % columns
            row = index // columns
            x = start_x + col * step_x
            y = start_y + row * (image_size + 68)
            paste_fit(canvas, folder / name, (x, y, x + image_size, y + image_size))
            draw_label(draw, name, x, y + image_size + 10, label_font)

    draw.text((34, 1552), "Seasonal Scene Backgrounds", fill=(64, 46, 34), font=title_font)
    for index, name in enumerate(SCENE_BACKGROUND_FILES):
        x = 34 + (index % 3) * 570
        y = 1610 + (index // 3) * 92
        paste_fit(canvas, root / "art" / "backgrounds" / name, (x, y, x + 210, y + 70))
        draw_label(draw, name, x + 222, y + 22, label_font)

    canvas.convert("RGB").save(output)
    print(f"Wrote {output}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a cow/crop asset QA contact sheet.")
    parser.add_argument("--root", default=".", help="Project root.")
    parser.add_argument(
        "--output",
        default="_qa_previews/cow_crop_contact_sheet.png",
        help="Output PNG path, relative to root unless absolute.",
    )
    parser.add_argument(
        "--extra-output",
        default="_qa_previews/seasonal_asset_contact_sheet.png",
        help="Extra QA contact sheet path, relative to root unless absolute.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    output = Path(args.output)
    if not output.is_absolute():
        output = root / output
    build_preview(root, output)
    extra_output = Path(args.extra_output)
    if not extra_output.is_absolute():
        extra_output = root / extra_output
    build_extra_preview(root, extra_output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
