from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ART_ROOT = ROOT / "art"
SCALE = 3


COLORS = {
    "outline": (80, 54, 42, 255),
    "outline_soft": (108, 73, 55, 255),
    "cream": (255, 242, 210, 255),
    "sky": (155, 221, 255, 255),
    "grass": (112, 198, 98, 255),
    "grass_dark": (80, 162, 83, 255),
    "dirt": (196, 137, 82, 255),
    "dirt_dark": (142, 92, 58, 255),
    "wood": (183, 116, 68, 255),
    "wood_dark": (125, 76, 49, 255),
    "barn_red": (224, 84, 72, 255),
    "barn_dark": (163, 55, 54, 255),
    "leaf": (93, 182, 91, 255),
    "leaf_light": (139, 219, 111, 255),
    "yellow": (255, 218, 88, 255),
    "orange": (245, 143, 62, 255),
    "pink": (255, 152, 176, 255),
    "blue": (103, 183, 232, 255),
    "purple": (183, 146, 232, 255),
    "white": (255, 255, 248, 255),
    "black": (70, 65, 64, 255),
}


def ensure_dirs() -> None:
    for folder in [
        "animals",
        "backgrounds",
        "props",
        "ui",
        "effects",
        "garden",
        "audio_prompts",
    ]:
        (ART_ROOT / folder).mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, relative: str) -> None:
    path = ART_ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


def rgba(color: tuple[int, int, int, int], alpha: int | None = None) -> tuple[int, int, int, int]:
    if alpha is None:
        return color
    return (color[0], color[1], color[2], alpha)


class Canvas:
    def __init__(self, width: int, height: int, transparent: bool = True):
        bg = (0, 0, 0, 0) if transparent else COLORS["sky"]
        self.width = width
        self.height = height
        self.image = Image.new("RGBA", (width * SCALE, height * SCALE), bg)
        self.draw = ImageDraw.Draw(self.image)

    def s(self, value: float) -> int:
        return int(round(value * SCALE))

    def box(self, coords: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
        return tuple(self.s(v) for v in coords)

    def poly(self, points: list[tuple[float, float]], fill, outline=None, width: int = 4) -> None:
        pts = [(self.s(x), self.s(y)) for x, y in points]
        self.draw.polygon(pts, fill=fill)
        if outline is not None and width > 0:
            self.draw.line(pts + [pts[0]], fill=outline, width=self.s(width), joint="curve")

    def ellipse(self, coords, fill, outline=COLORS["outline"], width: int = 8) -> None:
        self.draw.ellipse(self.box(coords), fill=fill, outline=outline, width=self.s(width))

    def rect(self, coords, fill, outline=COLORS["outline"], width: int = 8, radius: int = 24) -> None:
        self.draw.rounded_rectangle(self.box(coords), radius=self.s(radius), fill=fill, outline=outline, width=self.s(width))

    def line(self, points, fill=COLORS["outline"], width: int = 8) -> None:
        pts = [(self.s(x), self.s(y)) for x, y in points]
        self.draw.line(pts, fill=fill, width=self.s(width), joint="curve")

    def arc(self, coords, start: int, end: int, fill=COLORS["outline"], width: int = 7) -> None:
        self.draw.arc(self.box(coords), start, end, fill=fill, width=self.s(width))

    def finish(self) -> Image.Image:
        return self.image.resize((self.width, self.height), Image.Resampling.LANCZOS)


def draw_eye(canvas: Canvas, x: float, y: float, state: str = "open") -> None:
    if state == "blink" or state == "happy":
        canvas.arc((x - 17, y - 5, x + 17, y + 19), 10, 170, width=6)
    else:
        canvas.ellipse((x - 13, y - 16, x + 13, y + 16), COLORS["white"], width=5)
        canvas.ellipse((x - 6, y - 8, x + 6, y + 8), COLORS["black"], outline=COLORS["black"], width=1)


def draw_smile(canvas: Canvas, x: float, y: float, wide: bool = False) -> None:
    width = 42 if wide else 32
    canvas.arc((x - width, y - 12, x + width, y + 34), 20, 160, width=6)


def draw_shadow(canvas: Canvas, x: float, y: float, w: float, h: float) -> None:
    canvas.ellipse((x - w / 2, y - h / 2, x + w / 2, y + h / 2), (80, 60, 40, 38), outline=(0, 0, 0, 0), width=0)


def paste_center(c: Canvas, img: Image.Image, center_x: float, center_y: float, width: float) -> None:
    ratio = width / float(img.width)
    target_size = (c.s(width), c.s(img.height * ratio))
    resized = img.resize(target_size, Image.Resampling.LANCZOS)
    top_left = (c.s(center_x) - resized.width // 2, c.s(center_y) - resized.height // 2)
    c.image.alpha_composite(resized, top_left)


def animal_canvas() -> Canvas:
    c = Canvas(512, 512)
    draw_shadow(c, 256, 444, 270, 44)
    return c


def draw_cow(state: str) -> Image.Image:
    c = animal_canvas()
    body = (255, 249, 229, 255)
    body_light = (255, 254, 244, 255)
    spot = (82, 70, 66, 255)
    spot_soft = (116, 91, 73, 255)
    ear_inner = (242, 202, 178, 255)
    muzzle = (255, 184, 194, 255)
    muzzle_shadow = (232, 140, 155, 255)
    horn = (255, 236, 170, 255)
    udder = (255, 173, 190, 255)
    udder_shadow = (224, 119, 143, 255)
    hoof = (93, 63, 51, 255)

    # Tail and legs draw behind the rounded body.
    c.line([(394, 252), (442, 318)], fill=COLORS["outline"], width=9)
    c.line([(394, 252), (438, 314)], fill=(132, 86, 61, 255), width=5)
    c.ellipse((418, 302, 466, 354), spot, width=6)
    for x, y in [(144, 326), (210, 342), (316, 342), (374, 326)]:
        c.rect((x, y, x + 42, 430), body, width=8, radius=16)
        c.rect((x - 4, 404, x + 48, 444), hoof, width=6, radius=13)

    c.ellipse((82, 174, 430, 404), body, width=12)
    c.ellipse((128, 208, 338, 382), body_light, outline=body_light, width=1)
    c.ellipse((122, 206, 220, 292), spot, outline=spot, width=1)
    c.ellipse((280, 214, 358, 276), spot_soft, outline=spot_soft, width=1)
    c.ellipse((306, 296, 396, 374), spot, outline=spot, width=1)
    c.arc((128, 218, 396, 396), 18, 98, fill=(225, 206, 180, 255), width=8)

    # The udder sits tucked under the belly, with the cow body overlapping its top edge.
    c.ellipse((226, 348, 354, 436), udder, width=8)
    c.ellipse((264, 368, 318, 416), (255, 198, 210, 255), outline=(255, 198, 210, 255), width=1)
    for x in [248, 286, 324]:
        c.rect((x, 410, x + 18, 454), udder, width=5, radius=11)
        c.ellipse((x + 2, 438, x + 16, 458), udder_shadow, width=4)
    c.ellipse((196, 310, 382, 390), body_light, outline=body_light, width=1)
    c.arc((142, 238, 404, 406), 34, 118, fill=(224, 204, 176, 255), width=6)

    c.ellipse((86, 118, 174, 220), ear_inner, width=8)
    c.ellipse((338, 118, 426, 220), ear_inner, width=8)
    c.ellipse((146, 76, 366, 288), body, width=12)
    c.ellipse((178, 106, 334, 252), body_light, outline=body_light, width=1)
    c.poly([(176, 112), (198, 46), (226, 124)], horn, COLORS["outline"], 7)
    c.poly([(286, 124), (316, 46), (340, 112)], horn, COLORS["outline"], 7)
    c.ellipse((158, 132, 214, 186), spot, outline=spot, width=1)
    c.ellipse((212, 202, 324, 280), muzzle, width=8)
    c.ellipse((228, 232, 242, 246), COLORS["outline"], outline=COLORS["outline"], width=1)
    c.ellipse((294, 232, 308, 246), COLORS["outline"], outline=COLORS["outline"], width=1)
    c.arc((230, 250, 306, 286), 14, 166, fill=muzzle_shadow, width=5)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 214, 158, eye_state)
    draw_eye(c, 300, 158, eye_state)
    if state in ["happy", "excited", "celebrating"]:
        c.arc((230, 250, 306, 292), 18, 162, fill=COLORS["outline"], width=5)
    if state == "eating":
        draw_hay(c, 352, 278)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(118, 108), (404, 104), (394, 354)])
    return c.finish()


def draw_chicken(state: str) -> Image.Image:
	c = animal_canvas()
	body = (255, 231, 126, 255)
	body_light = (255, 248, 205, 255)
	wing = (255, 205, 93, 255)
	wing_dark = (226, 145, 61, 255)
	comb = (237, 82, 72, 255)
	comb_light = (255, 118, 99, 255)
	beak = (248, 145, 50, 255)
	feet = (230, 127, 48, 255)
	cheek = (255, 180, 145, 255)

	# Tail feathers first so the rounded body sits in front.
	c.poly([(132, 250), (58, 196), (144, 190)], wing, COLORS["outline"], 8)
	c.poly([(136, 286), (54, 268), (142, 226)], (255, 216, 108, 255), COLORS["outline"], 8)
	c.poly([(132, 322), (68, 348), (150, 274)], wing_dark, COLORS["outline"], 8)

	c.ellipse((108, 150, 404, 418), body, width=12)
	c.ellipse((156, 206, 338, 394), body_light, outline=body_light, width=1)
	c.arc((148, 190, 356, 390), 310, 82, fill=(238, 178, 78, 255), width=8)

	variant_offset = -4 if state == "excited" else 0
	c.ellipse((156, 92 + variant_offset, 356, 288 + variant_offset), (255, 242, 166, 255), width=12)
	c.ellipse((182, 138 + variant_offset, 330, 272 + variant_offset), body_light, outline=body_light, width=1)

	for x, y, rx, ry in [
		(210, 72 + variant_offset, 25, 42),
		(254, 62 + variant_offset, 31, 52),
		(300, 72 + variant_offset, 25, 42),
	]:
		c.ellipse((x - rx, y - ry, x + rx, y + ry), comb, width=7)
		c.ellipse((x - rx + 10, y - ry + 10, x + rx - 10, y + 2), comb_light, outline=comb_light, width=1)

	eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating", "excited"] else "open"
	draw_eye(c, 218, 168 + variant_offset, eye_state)
	draw_eye(c, 294, 168 + variant_offset, eye_state)
	c.ellipse((184, 198 + variant_offset, 220, 228 + variant_offset), cheek, outline=cheek, width=1)
	c.ellipse((304, 198 + variant_offset, 340, 228 + variant_offset), cheek, outline=cheek, width=1)

	if state == "excited":
		c.poly([(248, 190 + variant_offset), (310, 208 + variant_offset), (248, 232 + variant_offset)], beak, COLORS["outline"], 7)
		c.line([(264, 212 + variant_offset), (302, 210 + variant_offset)], fill=(151, 74, 42, 255), width=5)
	else:
		c.poly([(248, 186 + variant_offset), (310, 206 + variant_offset), (248, 226 + variant_offset)], beak, COLORS["outline"], 7)
	c.ellipse((258, 230 + variant_offset, 288, 260 + variant_offset), comb, width=5)
	c.ellipse((282, 232 + variant_offset, 308, 258 + variant_offset), comb, width=5)

	c.ellipse((88, 238, 188, 338), wing, width=9)
	c.line([(118, 272), (174, 316)], fill=wing_dark, width=7)
	c.line([(122, 304), (172, 286)], fill=(255, 232, 144, 255), width=7)

	if state in ["happy", "excited", "celebrating"]:
		c.ellipse((322, 216, 436, 322), wing, width=9)
		c.line([(350, 252), (414, 236)], fill=wing_dark, width=7)
		c.line([(356, 282), (416, 304)], fill=(255, 232, 144, 255), width=7)
	else:
		c.ellipse((318, 254, 416, 354), wing, width=9)
		c.line([(346, 292), (396, 330)], fill=wing_dark, width=7)

	if state == "eating":
		draw_feed_bits(c, 330, 236)
	if state in ["excited", "celebrating"]:
		draw_small_stars(c, [(116, 132), (400, 128), (392, 356)])

	leg_pairs = [(198, 164), (316, 356)] if state == "walking" else [(210, 188), (306, 330)]
	for leg_x, foot_x in leg_pairs:
		c.line([(leg_x, 398), (foot_x, 444)], fill=feet, width=8)
		c.line([(foot_x, 444), (foot_x - 28, 456)], fill=feet, width=8)
		c.line([(foot_x, 444), (foot_x + 30, 456)], fill=feet, width=8)
	return c.finish()


def draw_pig(state: str) -> Image.Image:
    c = animal_canvas()
    pink = (255, 164, 184, 255)
    pink_light = (255, 205, 214, 255)
    pink_mid = (255, 181, 197, 255)
    pink_dark = (231, 111, 142, 255)
    hoof = (118, 74, 65, 255)
    cheek = (255, 132, 157, 255)

    c.line([(392, 260), (442, 230), (420, 286), (452, 282)], fill=COLORS["outline"], width=9)
    c.line([(390, 260), (436, 236), (418, 280), (446, 278)], fill=pink_dark, width=5)
    # Walking for round preschool animals reads better as a small waddle than a long stride.
    leg_specs = [(144, 324, 94), (218, 340, 78), (312, 336, 82), (370, 322, 98)] if state == "walking" else [(150, 320, 100), (218, 338, 86), (314, 338, 86), (376, 320, 100)]
    for x, y, h in leg_specs:
        c.rect((x, y, x + 42, y + h), pink_mid, width=8, radius=16)
        hoof_offsets = {144: -5, 218: 2, 312: -4, 370: 2}
        hoof_offset = hoof_offsets.get(x, 0) if state == "walking" else 0
        c.rect((x - 6 + hoof_offset, y + h - 18, x + 48 + hoof_offset, y + h + 16), hoof, width=6, radius=13)

    c.ellipse((84, 166, 420, 408), pink, width=12)
    c.ellipse((138, 206, 350, 384), pink_light, outline=pink_light, width=1)
    c.arc((124, 210, 384, 392), 18, 112, fill=(226, 119, 145, 255), width=7)
    if state == "walking":
        c.arc((116, 262, 186, 350), 112, 226, fill=(255, 205, 214, 170), width=5)
        c.arc((336, 266, 400, 342), 310, 58, fill=(226, 119, 145, 165), width=5)

    c.ellipse((132, 78, 380, 306), pink_light, width=12)
    c.ellipse((172, 112, 348, 276), (255, 219, 226, 255), outline=(255, 219, 226, 255), width=1)
    c.poly([(164, 130), (118, 58), (228, 104)], pink, COLORS["outline"], 9)
    c.poly([(348, 130), (394, 58), (284, 104)], pink, COLORS["outline"], 9)
    c.poly([(166, 116), (138, 78), (204, 100)], (255, 190, 204, 255), COLORS["outline_soft"], 4)
    c.poly([(346, 116), (374, 78), (308, 100)], (255, 190, 204, 255), COLORS["outline_soft"], 4)

    c.ellipse((186, 188, 326, 282), pink_dark, width=8)
    c.ellipse((208, 202, 304, 258), (255, 157, 178, 255), outline=(255, 157, 178, 255), width=1)
    c.ellipse((220, 224, 236, 240), COLORS["outline"], outline=COLORS["outline"], width=1)
    c.ellipse((276, 224, 292, 240), COLORS["outline"], outline=COLORS["outline"], width=1)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 206, 160, eye_state)
    draw_eye(c, 306, 160, eye_state)
    c.ellipse((174, 178, 200, 198), cheek, outline=cheek, width=1)
    c.ellipse((312, 178, 338, 198), cheek, outline=cheek, width=1)
    draw_smile(c, 256, 254, True)
    if state == "eating":
        draw_feed_bits(c, 346, 286)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(114, 128), (394, 126), (388, 348)])
    return c.finish()


def draw_goat(state: str) -> Image.Image:
    c = animal_canvas()
    coat = (242, 222, 181, 255)
    coat_light = (255, 240, 203, 255)
    coat_shadow = (223, 193, 143, 255)
    muzzle = (238, 190, 154, 255)
    hoof = (105, 73, 57, 255)
    cheek = (255, 203, 176, 255)

    c.line([(402, 232), (448, 190)], fill=COLORS["outline"], width=8)
    c.line([(402, 232), (442, 196)], fill=coat_shadow, width=4)
    leg_specs = [(128, 326, 94), (218, 318, 108), (314, 344, 78), (394, 306, 114)] if state == "walking" else [(146, 314, 106), (212, 336, 88), (314, 336, 88), (374, 314, 106)]
    for x, y, h in leg_specs:
        c.rect((x, y, x + 38, y + h), coat_light, width=8, radius=15)
        c.rect((x - 6, y + h - 18, x + 44, y + h + 14), hoof, width=6, radius=12)

    c.ellipse((92, 176, 414, 408), coat, width=12)
    c.ellipse((140, 208, 350, 382), coat_light, outline=coat_light, width=1)
    c.arc((120, 206, 392, 390), 20, 110, fill=coat_shadow, width=7)

    c.ellipse((142, 72, 374, 304), coat_light, width=12)
    c.ellipse((180, 110, 342, 272), (255, 248, 218, 255), outline=(255, 248, 218, 255), width=1)
    c.poly([(176, 130), (118, 70), (226, 102)], coat, COLORS["outline"], 9)
    c.poly([(336, 130), (394, 70), (286, 102)], coat, COLORS["outline"], 9)
    c.poly([(202, 104), (220, 32), (242, 108)], (232, 204, 145, 255), COLORS["outline"], 8)
    c.poly([(270, 108), (292, 32), (312, 104)], (232, 204, 145, 255), COLORS["outline"], 8)
    c.line([(220, 48), (224, 98)], fill=(255, 232, 170, 255), width=4)
    c.line([(292, 48), (288, 98)], fill=(255, 232, 170, 255), width=4)

    c.ellipse((198, 206, 316, 292), muzzle, width=7)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 208, 158, eye_state)
    draw_eye(c, 304, 158, eye_state)
    c.ellipse((180, 180, 204, 198), cheek, outline=cheek, width=1)
    c.ellipse((308, 180, 332, 198), cheek, outline=cheek, width=1)
    draw_smile(c, 256, 256, True)
    c.poly([(226, 284), (256, 346), (286, 284)], muzzle, COLORS["outline"], 6)
    c.line([(242, 314), (270, 314)], fill=(156, 99, 76, 255), width=4)
    if state == "eating":
        draw_hay(c, 334, 280)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(128, 126), (386, 124), (390, 348)])
    return c.finish()


def draw_sheep(state: str) -> Image.Image:
    c = animal_canvas()
    wool = (255, 248, 228, 255)
    wool_light = (255, 255, 244, 255)
    wool_shadow = (226, 216, 188, 255)
    face = (236, 199, 166, 255)
    hoof = (104, 74, 60, 255)
    cheek = (255, 194, 174, 255)

    # Sheep wool hides most leg motion, so keep the steps short and grounded.
    leg_specs = [(140, 330, 88), (212, 346, 72), (306, 336, 82), (378, 330, 88)] if state == "walking" else [(150, 324, 94), (214, 346, 76), (306, 346, 76), (366, 324, 94)]
    for x, y, h in leg_specs:
        c.rect((x, y, x + 38, y + h), face, width=8, radius=16)
        hoof_offset = -8 if state == "walking" and x in [140, 306] else 8 if state == "walking" else 0
        c.rect((x - 6 + hoof_offset, y + h - 16, x + 44 + hoof_offset, y + h + 14), hoof, width=6, radius=12)

    c.ellipse((86, 168, 424, 402), wool, width=12)
    c.ellipse((132, 198, 364, 370), wool_light, outline=wool_light, width=1)
    if state == "walking":
        c.arc((112, 266, 194, 350), 118, 226, fill=wool_shadow, width=4)
        c.arc((324, 270, 398, 344), 312, 54, fill=wool_shadow, width=4)
    for x, y, rx, ry in [
        (136, 212, 62, 54),
        (202, 164, 70, 58),
        (286, 164, 70, 58),
        (356, 214, 62, 54),
        (166, 286, 72, 62),
        (252, 290, 80, 64),
        (340, 290, 70, 60),
    ]:
        c.ellipse((x - rx, y - ry, x + rx, y + ry), wool, width=8)
        c.arc((x - rx + 16, y - ry + 18, x + rx - 10, y + ry - 6), 188, 332, fill=wool_shadow, width=4)

    c.ellipse((166, 84, 346, 262), face, width=10)
    c.ellipse((190, 114, 322, 238), (247, 218, 186, 255), outline=(247, 218, 186, 255), width=1)
    c.ellipse((126, 136, 198, 218), face, width=7)
    c.ellipse((314, 136, 386, 218), face, width=7)
    for x, y, r in [(196, 92, 34), (238, 72, 40), (282, 72, 40), (318, 94, 34)]:
        c.ellipse((x - r, y - r, x + r, y + r), wool, width=7)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 218, 160, eye_state)
    draw_eye(c, 294, 160, eye_state)
    c.ellipse((196, 184, 218, 202), cheek, outline=cheek, width=1)
    c.ellipse((294, 184, 316, 202), cheek, outline=cheek, width=1)
    c.ellipse((250, 190, 264, 204), COLORS["outline"], outline=COLORS["outline"], width=1)
    draw_smile(c, 256, 222, True)
    if state == "eating":
        draw_hay(c, 330, 260)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(116, 126), (398, 126), (386, 344)])
    return c.finish()


def draw_pony(state: str) -> Image.Image:
    c = animal_canvas()
    coat = (208, 135, 78, 255)
    coat_light = (230, 158, 94, 255)
    muzzle = (238, 184, 137, 255)
    tail = (104, 66, 47, 255)
    hoof = (93, 61, 48, 255)
    cheek = (255, 177, 142, 255)
    inner_ear = (247, 190, 143, 255)

    # Tail and legs draw first so the rounded body reads as one soft pony shape.
    tail_lift = -16 if state in ["happy", "excited", "celebrating"] else 0
    c.line([(386, 252), (446, 308 + tail_lift)], fill=COLORS["outline"], width=18)
    c.line([(386, 252), (444, 306 + tail_lift)], fill=tail, width=10)
    c.ellipse((424, 292 + tail_lift, 470, 346 + tail_lift), tail, width=6)

    leg_specs = [(134, 316, 98), (208, 338, 78), (304, 338, 78), (374, 316, 98)]
    hoof_offsets = {134: 8, 208: -8, 304: 10, 374: -6} if state == "walking" else {}
    for x, top_y, leg_h in leg_specs:
        hoof_offset = hoof_offsets.get(x, 0)
        c.rect((x, top_y, x + 42, top_y + leg_h), coat, width=8, radius=15)
        c.line([(x + 28, top_y + 18), (x + 28, top_y + leg_h - 12)], fill=(176, 105, 63, 120), width=3)
        c.rect((x - 4 + hoof_offset, top_y + leg_h - 16, x + 48 + hoof_offset, top_y + leg_h + 22), hoof, width=6, radius=13)

    c.ellipse((76, 176, 436, 398), coat, width=12)
    c.ellipse((128, 210, 350, 376), coat_light, outline=coat_light, width=1)
    c.arc((142, 224, 400, 392), 24, 116, fill=(178, 105, 61, 150), width=7)

    head_offset = -5 if state == "excited" else 0
    c.poly([(178, 120 + head_offset), (140, 44 + head_offset), (230, 92 + head_offset)], coat, COLORS["outline"], 8)
    c.poly([(190, 105 + head_offset), (158, 62 + head_offset), (212, 92 + head_offset)], inner_ear, outline=(0, 0, 0, 0), width=0)
    c.poly([(334, 120 + head_offset), (372, 44 + head_offset), (282, 92 + head_offset)], coat, COLORS["outline"], 8)
    c.poly([(322, 105 + head_offset), (354, 62 + head_offset), (300, 92 + head_offset)], inner_ear, outline=(0, 0, 0, 0), width=0)

    c.ellipse((144, 78 + head_offset, 368, 292 + head_offset), coat, width=12)
    c.ellipse((184, 112 + head_offset, 334, 252 + head_offset), coat_light, outline=coat_light, width=1)

    c.ellipse((194, 198 + head_offset, 318, 286 + head_offset), muzzle, width=8)
    c.ellipse((214, 232 + head_offset, 230, 246 + head_offset), COLORS["outline"], outline=COLORS["outline"], width=1)
    c.ellipse((282, 232 + head_offset, 298, 246 + head_offset), COLORS["outline"], outline=COLORS["outline"], width=1)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 218, 158 + head_offset, eye_state)
    draw_eye(c, 296, 158 + head_offset, eye_state)
    c.ellipse((186, 190 + head_offset, 216, 216 + head_offset), cheek, outline=cheek, width=1)
    c.ellipse((296, 190 + head_offset, 326, 216 + head_offset), cheek, outline=cheek, width=1)
    draw_smile(c, 256, 250 + head_offset, True)
    if state == "eating":
        draw_hay(c, 344, 276)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(112, 118), (404, 120), (390, 348)])
    return c.finish()


def draw_duck(state: str) -> Image.Image:
    c = animal_canvas()
    c.ellipse((130, 184, 382, 406), (255, 226, 100, 255), width=10)
    c.ellipse((176, 86, 336, 248), (255, 238, 137, 255), width=10)
    c.poly([(234, 164), (314, 184), (234, 208)], (246, 133, 50, 255), COLORS["outline"], 7)
    c.ellipse((98, 254, 184, 342), (255, 213, 82, 255), width=8)
    c.ellipse((328, 254, 414, 342), (255, 213, 82, 255), width=8)
    eye_state = "blink" if state == "blinking" else "happy" if state in ["happy", "celebrating"] else "open"
    draw_eye(c, 218, 150, eye_state)
    draw_eye(c, 294, 150, eye_state)
    if state == "eating":
        draw_feed_bits(c, 330, 246)
    if state in ["excited", "celebrating"]:
        draw_small_stars(c, [(120, 132), (400, 132), (384, 350)])
    return c.finish()


def draw_small_stars(c: Canvas, points: list[tuple[float, float]]) -> None:
    for x, y in points:
        draw_star(c, x, y, 22, COLORS["yellow"])


def draw_star(c: Canvas, x: float, y: float, r: float, fill) -> None:
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + i * math.pi / 5
        radius = r if i % 2 == 0 else r * 0.45
        pts.append((x + math.cos(angle) * radius, y + math.sin(angle) * radius))
    c.poly(pts, fill, COLORS["outline"], 5)


def draw_hay(c: Canvas, x: float, y: float) -> None:
    for i in range(5):
        c.line([(x - 34 + i * 12, y + 20), (x - 8 + i * 8, y - 18)], fill=(225, 176, 72, 255), width=5)


def draw_feed_bits(c: Canvas, x: float, y: float) -> None:
    for i in range(6):
        c.ellipse((x + i * 10 - 26, y + (i % 2) * 8, x + i * 10 - 16, y + 10 + (i % 2) * 8), (226, 166, 73, 255), width=2)


def generate_animals() -> None:
    # Duck sprites are approved image-generated mallard art and are kept out of
    # this deterministic batch so a future regeneration cannot restore yellow
    # duck sprites over the runtime assets.
    animals = {
        "cow": draw_cow,
        "chicken": draw_chicken,
        "pig": draw_pig,
        "goat": draw_goat,
        "sheep": draw_sheep,
        "pony": draw_pony,
    }
    states = ["idle", "happy", "excited", "blinking", "eating", "celebrating", "walking"]
    for name, drawer in animals.items():
        frames = []
        for state in states:
            img = drawer(state)
            frames.append(img)
            save(img, f"animals/{name}_{state}.png")
        sheet = Image.new("RGBA", (512 * len(frames), 512), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (512 * index, 0))
        save(sheet, f"animals/{name}_states_sheet.png")


def generate_hub_feed_animals() -> None:
    hub_animals = {
        "hub_feed_sheep": draw_hub_feed_sheep,
        "hub_feed_pig": draw_hub_feed_pig,
        "hub_feed_chicken": draw_hub_feed_chicken,
        "hub_feed_goat": draw_hub_feed_goat,
    }
    for name, drawer in hub_animals.items():
        img = drawer()
        save(img, f"animals/{name}.png")


def prop_canvas(size: int = 512) -> Canvas:
    return Canvas(size, size)


def make_egg(golden: bool = False) -> Image.Image:
    c = prop_canvas()
    fill = (255, 220, 76, 255) if golden else (255, 245, 211, 255)
    fill_light = (255, 241, 134, 255) if golden else (255, 253, 238, 255)
    shade = (226, 143, 43, 255) if golden else (235, 205, 160, 255)

    def mix_color(a, b, amount: float) -> tuple[int, int, int, int]:
        return (
            int(round(a[0] + (b[0] - a[0]) * amount)),
            int(round(a[1] + (b[1] - a[1]) * amount)),
            int(round(a[2] + (b[2] - a[2]) * amount)),
            255,
        )

    def egg_points(cx: float, top: float, height: float, width_scale: float = 1.0) -> list[tuple[float, float]]:
        right: list[tuple[float, float]] = []
        left: list[tuple[float, float]] = []
        for i in range(42):
            t = float(i) / 41.0
            y = top + height * t
            rounded = pow(math.sin(max(0.0, min(1.0, t)) * math.pi), 0.56)
            half_width = rounded * (72.0 + 38.0 * t) * width_scale
            right.append((cx + half_width, y))
            left.insert(0, (cx - half_width, y))
        return right + left

    draw_shadow(c, 256, 426, 218, 34)

    # Draw a custom egg silhouette instead of a plain oval: narrower top, fuller bottom.
    c.poly(egg_points(256, 62, 362, 1.0), COLORS["outline"], None, 0)
    c.poly(egg_points(256, 76, 330, 0.88), fill, None, 0)
    c.poly(egg_points(278, 104, 282, 0.55), mix_color(fill, shade, 0.28), None, 0)
    c.poly(egg_points(240, 92, 278, 0.62), mix_color(fill, fill_light, 0.55), None, 0)
    c.arc((186, 128, 340, 388), 334, 76, fill=mix_color(fill, shade, 0.52), width=8)
    c.arc((204, 276, 326, 402), 12, 82, fill=mix_color(fill, shade, 0.36), width=8)
    c.ellipse((194, 106, 278, 238), mix_color(fill, COLORS["white"], 0.68), outline=(0, 0, 0, 0), width=0)
    c.ellipse((214, 124, 262, 198), mix_color(fill, COLORS["white"], 0.84), outline=(0, 0, 0, 0), width=0)
    for x, y, size, amount in [(210, 308, 7, 0.28), (286, 286, 6, 0.24), (242, 354, 5, 0.22)]:
        c.ellipse((x - size, y - size, x + size, y + size), mix_color(fill, shade, amount), outline=(0, 0, 0, 0), width=0)
    if golden:
        draw_star(c, 260, 236, 44, (255, 244, 152, 255))
        c.ellipse((324, 154, 342, 172), mix_color(fill, COLORS["white"], 0.72), outline=(0, 0, 0, 0), width=0)
        c.ellipse((174, 252, 188, 266), mix_color(fill, COLORS["white"], 0.62), outline=(0, 0, 0, 0), width=0)
    return c.finish()


def make_basket() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 430, 270, 34)
    c.arc((118, 74, 394, 316), 190, 350, width=18)
    c.rect((112, 194, 400, 408), (212, 137, 72, 255), width=12, radius=46)
    for x in [164, 220, 276, 332]:
        c.line([(x, 206), (x - 28, 396)], fill=(153, 88, 52, 255), width=10)
        c.line([(x - 44, 244), (x + 70, 244)], fill=(238, 166, 91, 255), width=8)
    c.rect((98, 190, 414, 244), (237, 161, 82, 255), width=10, radius=32)
    return c.finish()


def make_basket_front() -> Image.Image:
    c = prop_canvas()
    # Front-only overlay lets collected eggs render between the basket back and lip.
    c.rect((112, 194, 400, 408), (212, 137, 72, 255), width=12, radius=46)
    for x in [164, 220, 276, 332]:
        c.line([(x, 206), (x - 28, 396)], fill=(153, 88, 52, 255), width=10)
        c.line([(x - 44, 244), (x + 70, 244)], fill=(238, 166, 91, 255), width=8)
    c.rect((98, 190, 414, 244), (237, 161, 82, 255), width=10, radius=32)
    return c.finish()


def make_bucket() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 420, 230, 32)
    c.arc((152, 72, 360, 280), 190, 350, width=12)
    c.poly([(152, 172), (360, 172), (330, 410), (182, 410)], (232, 244, 252, 255), COLORS["outline"], 12)
    c.ellipse((150, 142, 362, 216), (206, 226, 238, 255), width=12)
    c.ellipse((174, 158, 338, 206), (181, 207, 224, 255), outline=(118, 154, 177, 255), width=5)
    c.line([(184, 254), (334, 254)], fill=(255, 255, 255, 130), width=8)
    c.line([(178, 308), (338, 308)], fill=(191, 222, 238, 255), width=6)
    return c.finish()


def make_bucket_front() -> Image.Image:
    c = prop_canvas()
    # Front-only outline keeps the animated milk visible while still reading as inside the pail.
    c.line([(152, 172), (182, 410), (330, 410), (360, 172)], fill=COLORS["outline"], width=12)
    c.arc((150, 142, 362, 216), 0, 180, fill=(118, 154, 177, 255), width=5)
    c.line([(184, 254), (334, 254)], fill=(255, 255, 255, 130), width=8)
    c.line([(178, 308), (338, 308)], fill=(191, 222, 238, 255), width=6)
    return c.finish()


def make_feed_bag() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 430, 230, 34)
    c.rect((150, 92, 362, 420), (245, 204, 119, 255), width=12, radius=42)
    c.poly([(160, 118), (220, 70), (304, 70), (354, 118)], (232, 176, 91, 255), COLORS["outline"], 10)
    c.rect((184, 202, 328, 290), (255, 238, 170, 255), width=8, radius=24)
    draw_feed_bits(c, 236, 234)
    return c.finish()


def make_feed_scoop() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 258, 404, 230, 34)
    c.ellipse((126, 126, 338, 330), (255, 210, 95, 255), width=12)
    c.poly([(302, 282), (424, 372), (390, 418), (270, 322)], (238, 151, 72, 255), COLORS["outline"], 11)
    for i in range(8):
        c.ellipse((170 + i * 20, 218 + (i % 2) * 18, 188 + i * 20, 236 + (i % 2) * 18), (176, 104, 54, 255), width=3)
    return c.finish()


def make_feed_pile() -> Image.Image:
    c = prop_canvas()
    grain = (247, 207, 119, 255)
    grain_light = (255, 231, 146, 255)
    grain_dark = (213, 164, 74, 255)

    # A simple pile is placed over the troughs already painted into the feeding
    # background. It must never include a second trough or container.
    draw_shadow(c, 256, 328, 236, 42)
    c.ellipse((112, 202, 400, 326), (189, 132, 64, 190), outline=(0, 0, 0, 0), width=0)
    c.ellipse((122, 172, 390, 288), grain, outline=COLORS["outline"], width=8)
    c.ellipse((150, 180, 356, 252), grain_light, outline=(0, 0, 0, 0), width=0)
    for gx, gy, rx, ry, color in [
        (154, 226, 10, 7, grain_dark),
        (182, 200, 9, 7, grain_light),
        (210, 240, 8, 6, grain_dark),
        (240, 212, 10, 7, grain_light),
        (270, 244, 8, 6, grain_dark),
        (300, 204, 9, 7, grain_light),
        (332, 234, 8, 6, grain_dark),
        (360, 220, 7, 5, grain_light),
    ]:
        c.ellipse((gx - rx, gy - ry, gx + rx, gy + ry), color, outline=(0, 0, 0, 0), width=0)
    return c.finish()


def make_feed_pour() -> Image.Image:
    c = prop_canvas()
    grain = (247, 207, 119, 255)
    grain_light = (255, 231, 146, 255)
    grain_dark = (213, 164, 74, 255)
    for x, y, radius, color in [
        (236, 170, 8, grain_light),
        (252, 196, 7, grain),
        (268, 222, 8, grain_dark),
        (246, 252, 7, grain),
        (262, 282, 9, grain_light),
        (278, 312, 8, grain),
        (252, 338, 7, grain_dark),
        (286, 352, 8, grain_light),
    ]:
        c.ellipse((x - radius, y - radius, x + radius, y + radius), color, outline=(0, 0, 0, 0), width=0)
    c.line([(238, 176), (278, 320)], fill=(255, 224, 126, 180), width=8)
    c.line([(254, 206), (288, 346)], fill=(225, 166, 73, 150), width=6)
    return c.finish()


def make_brush() -> Image.Image:
    c = prop_canvas()
    wood = (225, 151, 78, 255)
    wood_light = (255, 191, 105, 255)
    wood_dark = (133, 82, 54, 255)
    pad = (122, 202, 222, 255)
    pad_light = (170, 232, 242, 255)
    bristle = (103, 71, 54, 255)

    draw_shadow(c, 260, 408, 292, 36)
    c.rect((292, 176, 452, 248), wood, width=11, radius=34)
    c.line([(318, 194), (424, 194)], fill=wood_light, width=9)
    c.line([(338, 226), (420, 226)], fill=wood_dark, width=6)
    c.ellipse((416, 196, 442, 222), (255, 224, 145, 255), width=5)
    c.rect((278, 178, 330, 246), wood_dark, width=8, radius=22)

    c.rect((104, 128, 334, 278), (255, 227, 168, 255), width=12, radius=48)
    c.rect((128, 150, 310, 242), pad, width=8, radius=34)
    c.rect((154, 164, 292, 214), pad_light, outline=(0, 0, 0, 0), width=0, radius=24)
    c.line([(128, 250), (310, 250)], fill=wood_dark, width=8)
    for index, x in enumerate(range(142, 306, 24)):
        end_y = 334 + (index % 2) * 10
        c.line([(x, 254), (x - 10, end_y)], fill=COLORS["outline"], width=8)
        c.line([(x, 260), (x - 9, end_y - 4)], fill=bristle, width=5)
    c.line([(164, 132), (294, 132)], fill=(255, 242, 191, 190), width=5)
    return c.finish()


def make_watering_can() -> Image.Image:
    c = prop_canvas()
    blue = (110, 198, 225, 255)
    blue_light = (164, 231, 241, 255)
    blue_dark = (70, 143, 178, 255)
    rim = (242, 245, 220, 255)

    draw_shadow(c, 258, 416, 292, 36)
    c.arc((78, 170, 222, 346), 78, 282, fill=COLORS["outline"], width=20)
    c.arc((98, 190, 196, 326), 82, 278, fill=blue_dark, width=15)
    c.rect((142, 168, 340, 382), blue, width=13, radius=58)
    c.rect((166, 142, 310, 200), rim, width=10, radius=28)
    c.rect((188, 162, 292, 188), blue_light, outline=(0, 0, 0, 0), width=0, radius=18)
    c.ellipse((170, 198, 318, 330), rgba(blue_light, 110), outline=(0, 0, 0, 0), width=0)
    c.line([(182, 228), (302, 214)], fill=(208, 247, 249, 150), width=8)
    c.line([(180, 270), (294, 260)], fill=blue_dark, width=7)
    c.line([(212, 376), (284, 376)], fill=COLORS["outline"], width=10)

    c.poly([(326, 210), (438, 164), (458, 198), (350, 258)], blue, COLORS["outline"], 11)
    c.line([(350, 226), (426, 194)], fill=blue_light, width=8)
    c.ellipse((432, 166, 468, 206), rim, width=7)
    c.rect((244, 112, 288, 162), blue, width=8, radius=18)
    for index, (x, y, r) in enumerate([(438, 244, 11), (466, 278, 10), (420, 294, 8)]):
        c.poly([(x, y - r * 2), (x + r, y), (x, y + r * 2), (x - r, y)], (83, 176, 230, 235), COLORS["outline"], 3)
    return c.finish()


def make_hay_bale() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 394, 290, 34)
    c.rect((104, 168, 408, 356), (245, 193, 77, 255), width=12, radius=42)
    for y in [210, 256, 302]:
        c.line([(124, y), (388, y + 8)], fill=(210, 151, 61, 255), width=8)
    c.line([(210, 174), (210, 352)], fill=(154, 93, 64, 255), width=9)
    c.line([(306, 174), (306, 352)], fill=(154, 93, 64, 255), width=9)
    return c.finish()


def make_nest() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 396, 340, 42)

    straw_dark = (130, 84, 48, 255)
    straw_mid = (205, 137, 72, 255)
    straw_light = (252, 207, 111, 255)
    straw_warm = (235, 176, 90, 255)

    # Wide, friendly nest silhouette sized to read clearly on mobile.
    c.ellipse((72, 162, 440, 402), straw_mid, width=12)
    c.ellipse((112, 196, 400, 360), straw_dark, width=8)
    c.ellipse((138, 218, 374, 342), (151, 96, 54, 255), outline=(151, 96, 54, 255), width=1)
    c.ellipse((84, 244, 428, 416), straw_warm, width=10)
    c.ellipse((124, 264, 388, 374), straw_light, outline=straw_light, width=1)

    for start, end, color, width in [
        ((100, 316), (198, 256), straw_light, 8),
        ((132, 370), (244, 280), straw_mid, 7),
        ((196, 392), (300, 264), straw_dark, 7),
        ((276, 382), (390, 292), straw_light, 8),
        ((88, 266), (192, 338), straw_dark, 7),
        ((318, 262), (424, 338), straw_mid, 7),
        ((154, 232), (270, 184), straw_light, 7),
        ((244, 184), (370, 242), straw_dark, 7),
    ]:
        c.line([start, end], fill=color, width=width)

    for x, y, r, color in [
        (126, 252, 10, straw_light),
        (178, 302, 8, straw_mid),
        (250, 278, 9, straw_dark),
        (320, 314, 8, straw_mid),
        (376, 264, 9, straw_light),
    ]:
        c.ellipse((x - r, y - r, x + r, y + r), color, outline=color, width=1)

    return c.finish()


def make_chicken_nest(kind: str) -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 400, 330, 38)

    straw_dark = (131, 82, 48, 255)
    straw_mid = (214, 143, 68, 255)
    straw_light = (255, 210, 108, 255)
    straw_gold = (241, 180, 81, 255)
    wood = (191, 112, 62, 255)
    wood_dark = (125, 73, 48, 255)

    if kind == "wood_box":
        c.rect((82, 176, 430, 394), wood, width=12, radius=34)
        c.rect((116, 210, 396, 354), (151, 86, 53, 255), width=8, radius=32)
        for y in [222, 282, 342]:
            c.line([(106, y), (408, y + 4)], fill=wood_dark, width=6)
        for x in [164, 256, 348]:
            c.line([(x, 184), (x - 8, 392)], fill=(228, 152, 83, 255), width=7)
        c.ellipse((126, 230, 386, 382), straw_gold, width=8)
        c.ellipse((156, 250, 356, 348), straw_light, outline=straw_light, width=1)
        c.line([(152, 298), (248, 244), (358, 300)], fill=straw_dark, width=8)
        c.line([(174, 340), (286, 268), (372, 336)], fill=straw_mid, width=7)
    elif kind == "woven_bowl":
        c.ellipse((78, 160, 434, 408), straw_mid, width=12)
        c.ellipse((112, 188, 400, 360), straw_dark, width=9)
        c.ellipse((132, 226, 380, 382), straw_gold, width=9)
        c.ellipse((158, 248, 354, 346), straw_light, outline=straw_light, width=1)
        for arc_offset, color in [(0, straw_dark), (24, straw_light), (48, straw_mid)]:
            c.arc((104 + arc_offset, 190, 408 - arc_offset, 390), 188, 352, fill=color, width=8)
        for start, end, color in [
            ((112, 276), (210, 216), straw_light),
            ((144, 360), (258, 258), straw_dark),
            ((226, 386), (322, 246), straw_mid),
            ((314, 354), (420, 282), straw_light),
        ]:
            c.line([start, end], fill=color, width=8)
    elif kind == "hay_pocket":
        c.poly([(78, 330), (142, 190), (254, 146), (372, 190), (438, 330), (386, 406), (130, 406)], straw_mid, COLORS["outline"], 12)
        c.ellipse((124, 222, 388, 374), straw_gold, width=9)
        c.ellipse((158, 248, 354, 340), straw_light, outline=straw_light, width=1)
        c.line([(120, 332), (218, 204), (328, 338)], fill=straw_dark, width=8)
        c.line([(166, 388), (264, 226), (390, 332)], fill=straw_light, width=8)
        c.line([(92, 288), (194, 356), (308, 218), (426, 288)], fill=straw_dark, width=7)
        for x, y in [(142, 234), (206, 186), (326, 190), (380, 238)]:
            c.ellipse((x - 12, y - 12, x + 12, y + 12), straw_light, outline=straw_light, width=1)

    return c.finish()


def make_simple_prop(kind: str) -> Image.Image:
    c = prop_canvas()
    if kind == "cloud":
        for x, y, r in [(160, 278, 58), (222, 238, 78), (302, 250, 70), (356, 288, 52)]:
            c.ellipse((x - r, y - r, x + r, y + r), COLORS["white"], width=8)
    elif kind == "tree":
        c.rect((230, 242, 282, 420), (136, 87, 55, 255), width=8, radius=18)
        for x, y, r in [(194, 212, 86), (268, 172, 98), (338, 220, 82), (264, 254, 92)]:
            c.ellipse((x - r, y - r, x + r, y + r), COLORS["leaf_light"], width=10)
    elif kind == "bush":
        for x, y, r in [(150, 318, 64), (222, 276, 82), (308, 292, 76), (370, 330, 58)]:
            c.ellipse((x - r, y - r, x + r, y + r), COLORS["leaf_light"], width=9)
    elif kind == "fence_panel":
        for x in [114, 214, 314, 414]:
            c.rect((x - 24, 128, x + 24, 398), (230, 173, 106, 255), width=8, radius=14)
        c.rect((70, 188, 442, 244), (219, 151, 86, 255), width=8, radius=20)
        c.rect((70, 304, 442, 360), (219, 151, 86, 255), width=8, radius=20)
    elif kind == "dirt_path":
        c.poly([(184, 96), (328, 96), (438, 430), (74, 430)], (211, 147, 88, 255), COLORS["outline"], 10)
        for x, y in [(194, 178), (292, 220), (240, 318), (354, 356)]:
            c.ellipse((x - 20, y - 10, x + 20, y + 10), (175, 108, 66, 100), outline=(0, 0, 0, 0), width=0)
    elif kind == "chicken_coop":
        draw_shadow(c, 256, 424, 330, 36)
        wood = (221, 136, 73, 255)
        wood_light = (247, 176, 95, 255)
        wood_dark = (116, 69, 47, 255)
        roof = (232, 78, 68, 255)
        roof_light = (255, 121, 96, 255)
        hay = (255, 216, 104, 255)

        c.rect((118, 312, 158, 430), wood_dark, width=7, radius=14)
        c.rect((354, 312, 394, 430), wood_dark, width=7, radius=14)
        c.rect((94, 182, 418, 408), wood, width=12, radius=34)
        for x in [150, 214, 278, 342]:
            c.line([(x, 196), (x - 14, 394)], fill=(169, 91, 54, 255), width=8)
            c.line([(x + 10, 204), (x + 44, 204)], fill=wood_light, width=6)

        c.poly([(58, 196), (256, 54), (454, 196)], roof, COLORS["outline"], 12)
        c.poly([(124, 176), (256, 86), (388, 176)], roof_light, outline=roof_light, width=1)
        c.rect((70, 182, 442, 220), (158, 86, 57, 255), width=9, radius=18)
        c.rect((92, 174, 420, 206), roof_light, width=7, radius=16)

        c.rect((202, 262, 310, 408), wood_dark, width=8, radius=24)
        c.ellipse((204, 226, 310, 314), wood_dark, width=8)
        c.rect((226, 292, 286, 408), (91, 57, 42, 255), outline=(91, 57, 42, 255), width=1, radius=12)
        c.ellipse((248, 312, 266, 330), hay, outline=hay, width=1)

        c.rect((118, 252, 200, 330), (255, 238, 172, 255), width=7, radius=20)
        c.ellipse((136, 270, 184, 314), (255, 230, 119, 255), width=5)
        draw_eye(c, 150, 288, "open")
        c.poly([(166, 292), (196, 304), (166, 316)], (248, 145, 50, 255), COLORS["outline"], 4)

        c.rect((326, 258, 400, 332), (171, 96, 55, 255), width=7, radius=18)
        c.ellipse((342, 282, 362, 306), (255, 247, 218, 255), width=4)
        c.ellipse((366, 278, 388, 304), (255, 247, 218, 255), width=4)
        c.line([(330, 332), (402, 332)], fill=hay, width=9)

        c.rect((112, 222, 404, 248), (255, 219, 125, 255), width=6, radius=12)
        c.line([(132, 366), (382, 366)], fill=(111, 68, 45, 255), width=9)
        c.line([(150, 374), (190, 398)], fill=(111, 68, 45, 255), width=7)
        c.line([(362, 374), (322, 398)], fill=(111, 68, 45, 255), width=7)
    elif kind == "barn":
        c.rect((112, 150, 400, 420), COLORS["barn_red"], width=12, radius=26)
        c.poly([(76, 162), (256, 56), (436, 162)], COLORS["barn_dark"], COLORS["outline"], 12)
        c.rect((206, 272, 306, 420), (110, 64, 48, 255), width=9, radius=12)
        c.line([(206, 272), (306, 420)], fill=COLORS["white"], width=8)
        c.line([(306, 272), (206, 420)], fill=COLORS["white"], width=8)
    return c.finish()


def make_cow_milking_stanchion() -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 424, 330, 36)
    c.rect((84, 158, 428, 404), (239, 193, 126, 255), width=11, radius=34)
    c.rect((116, 92, 172, 410), (194, 125, 74, 255), width=9, radius=18)
    c.rect((340, 92, 396, 410), (194, 125, 74, 255), width=9, radius=18)
    c.rect((102, 128, 410, 178), (221, 151, 86, 255), width=9, radius=20)
    paste_center(c, draw_cow("happy"), 256, 266, 304)
    c.rect((118, 286, 392, 332), (221, 151, 86, 255), width=9, radius=20)
    c.rect((156, 332, 210, 420), (194, 125, 74, 255), width=8, radius=16)
    c.rect((302, 332, 356, 420), (194, 125, 74, 255), width=8, radius=16)
    c.arc((206, 284, 306, 390), 194, 346, width=8)
    c.poly([(214, 332), (298, 332), (286, 410), (226, 410)], (235, 245, 252, 255), COLORS["outline"], 7)
    c.ellipse((210, 316, 302, 350), (248, 253, 255, 255), width=7)
    return c.finish()


def make_milking_stanchion_frame() -> Image.Image:
    c = prop_canvas()
    wood = (186, 118, 69, 255)
    wood_light = (225, 159, 92, 255)
    wood_dark = (122, 75, 47, 255)
    cream = (255, 241, 213, 255)
    draw_shadow(c, 256, 428, 300, 34)

    c.rect((92, 126, 142, 414), wood_light, width=10, radius=18)
    c.rect((370, 126, 420, 414), wood_light, width=10, radius=18)
    c.rect((118, 104, 394, 156), wood, width=10, radius=18)
    c.rect((104, 164, 408, 236), wood_dark, width=10, radius=20)
    c.rect((138, 184, 374, 220), cream, width=0, outline=(0, 0, 0, 0), radius=18)
    c.line([(198, 184), (198, 220)], fill=wood, width=8)
    c.line([(314, 184), (314, 220)], fill=wood, width=8)
    c.line([(228, 184), (280, 220)], fill=wood, width=8)
    c.line([(280, 184), (228, 220)], fill=wood, width=8)

    c.rect((108, 268, 412, 320), wood, width=10, radius=18)
    c.rect((148, 332, 372, 370), wood_light, width=10, radius=16)
    c.rect((136, 382, 384, 414), wood_dark, width=10, radius=16)
    c.line([(126, 156), (96, 120)], fill=wood_dark, width=8)
    c.line([(402, 156), (418, 120)], fill=wood_dark, width=8)
    c.line([(126, 320), (104, 382)], fill=wood_dark, width=8)
    c.line([(402, 320), (414, 382)], fill=wood_dark, width=8)
    return c.finish()


def draw_hub_feed_sheep() -> Image.Image:
    return draw_sheep("eating")


def draw_hub_feed_pig() -> Image.Image:
    return draw_pig("eating")


def draw_hub_feed_chicken() -> Image.Image:
    return draw_chicken("eating")


def draw_hub_feed_goat() -> Image.Image:
    return draw_goat("eating")


def make_hub_feed_pen() -> Image.Image:
    c = prop_canvas()

    wood_post = (226, 168, 101, 255)
    wood_post_dark = (171, 106, 62, 255)
    wood_rail = (220, 147, 82, 255)
    wood_rail_light = (246, 188, 111, 255)
    grass_mid = (122, 198, 101, 255)
    grass_light = (163, 222, 126, 255)
    grass_shadow = (86, 159, 86, 255)
    dirt_patch = (203, 143, 84, 255)
    dirt_dark = (148, 91, 58, 255)
    bucket_blue = (118, 195, 226, 255)
    bucket_dark = (73, 149, 196, 255)

    draw_shadow(c, 256, 440, 380, 44)

    # A soft oval feeding nook reads as environmental space rather than a flat UI icon.
    c.ellipse((42, 208, 470, 442), grass_mid, outline=(0, 0, 0, 0), width=0)
    c.ellipse((72, 226, 440, 414), grass_light, outline=(0, 0, 0, 0), width=0)
    c.arc((78, 240, 434, 414), 10, 170, fill=grass_shadow, width=6)
    c.ellipse((132, 286, 386, 410), (dirt_patch[0], dirt_patch[1], dirt_patch[2], 94), outline=(0, 0, 0, 0), width=0)
    c.ellipse((172, 312, 348, 394), (dirt_dark[0], dirt_dark[1], dirt_dark[2], 60), outline=(0, 0, 0, 0), width=0)

    # Back and side fence pieces establish the enclosed pen before the animal sprites draw.
    for x, y in [(66, 156), (146, 136), (256, 128), (366, 136), (446, 156)]:
        c.rect((x - 15, y, x + 15, 374), wood_post, width=7, radius=12)
        c.line([(x - 3, y + 22), (x - 3, 350)], fill=wood_post_dark, width=3)
        c.line([(x + 5, y + 28), (x + 5, 340)], fill=wood_rail_light, width=2)
        c.rect((x - 21, y - 16, x + 21, y + 10), wood_post_dark, width=6, radius=8)
    c.rect((36, 186, 476, 224), wood_rail, width=8, radius=18)
    c.line([(54, 199), (458, 199)], fill=wood_rail_light, width=4)
    c.rect((46, 262, 466, 298), wood_rail, width=8, radius=18)
    c.line([(62, 274), (450, 274)], fill=wood_rail_light, width=4)

    # Low side rails help the pen read as a rounded enclosure without hiding the animals.
    c.line([(64, 224), (44, 344)], fill=wood_post_dark, width=8)
    c.line([(448, 224), (468, 344)], fill=wood_post_dark, width=8)
    c.rect((54, 342, 132, 376), wood_rail, width=7, radius=16)
    c.rect((380, 342, 458, 376), wood_rail, width=7, radius=16)

    # A few curated props support the story without cluttering the farm hub.
    c.rect((84, 334, 140, 398), bucket_blue, width=7, radius=15)
    c.arc((72, 318, 152, 358), 182, 358, width=8)
    c.line([(92, 362), (136, 362)], fill=bucket_dark, width=5)
    c.ellipse((96, 372, 134, 388), (188, 226, 242, 255), outline=(0, 0, 0, 0), width=0)

    c.rect((374, 270, 430, 350), (248, 206, 119, 255), width=7, radius=17)
    c.ellipse((382, 254, 422, 290), (232, 176, 91, 255), width=6)
    c.line([(386, 298), (418, 308)], fill=(176, 104, 54, 120), width=4)
    c.ellipse((392, 322, 416, 346), (176, 104, 54, 64), outline=(0, 0, 0, 0), width=0)

    for start, end, color in [
        ((104, 390), (154, 360), (225, 176, 72, 255)),
        ((184, 394), (222, 368), (255, 216, 104, 255)),
        ((318, 390), (286, 360), (225, 176, 72, 255)),
        ((360, 390), (402, 366), (255, 216, 104, 255)),
    ]:
        c.line([start, end], fill=color, width=5)

    return c.finish()


def make_hub_feed_trough_front() -> Image.Image:
    c = prop_canvas()
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    trough_wood = (188, 118, 66, 255)
    trough_dark = (118, 72, 45, 255)
    trough_light = (236, 166, 92, 255)
    grain = (247, 207, 119, 255)
    grain_dark = (213, 164, 74, 255)

    # Transparent foreground overlay: front rail plus trough make animals sit inside the FeedArea pen.
    c.rect((44, 334, 468, 374), wood, width=8, radius=18)
    c.line([(62, 348), (450, 348)], fill=wood_light, width=4)
    c.rect((62, 398, 450, 434), wood_dark, outline=(0, 0, 0, 0), width=0, radius=20)
    for x in [66, 150, 256, 362, 446]:
        c.rect((x - 14, 304, x + 14, 426), wood, width=7, radius=12)
        c.line([(x + 5, 322), (x + 5, 408)], fill=wood_light, width=2)
        c.rect((x - 20, 292, x + 20, 316), wood_dark, width=6, radius=8)

    c.rect((128, 302, 384, 392), trough_wood, width=9, radius=22)
    c.rect((144, 312, 368, 364), trough_dark, width=6, radius=16)
    c.rect((156, 318, 356, 350), grain, outline=(0, 0, 0, 0), width=0, radius=12)
    c.line([(148, 374), (364, 374)], fill=trough_light, width=7)
    c.rect((136, 370, 376, 410), trough_dark, outline=(0, 0, 0, 0), width=0, radius=18)
    for gx, gy in [(178, 326), (208, 338), (242, 324), (278, 338), (318, 326), (340, 340)]:
        c.ellipse((gx - 6, gy - 4, gx + 6, gy + 4), grain_dark, outline=(0, 0, 0, 0), width=0)
    return c.finish()


def make_feeding_station_back() -> Image.Image:
    c = prop_canvas()
    grass = (122, 198, 101, 255)
    grass_light = (165, 222, 128, 255)
    dirt = (203, 143, 84, 255)
    dirt_dark = (148, 91, 58, 255)
    straw = (238, 197, 100, 255)

    draw_shadow(c, 256, 438, 300, 34)
    c.ellipse((82, 246, 430, 440), grass, outline=(0, 0, 0, 0), width=0)
    c.ellipse((112, 264, 400, 414), grass_light, outline=(0, 0, 0, 0), width=0)
    c.ellipse((148, 308, 364, 420), (dirt[0], dirt[1], dirt[2], 112), outline=(0, 0, 0, 0), width=0)
    c.ellipse((188, 332, 326, 398), (dirt_dark[0], dirt_dark[1], dirt_dark[2], 62), outline=(0, 0, 0, 0), width=0)
    for start, end, color in [
        ((124, 396), (170, 368), straw),
        ((212, 408), (244, 382), (255, 219, 112, 255)),
        ((322, 402), (286, 372), straw),
        ((366, 394), (398, 374), (255, 219, 112, 255)),
    ]:
        c.line([start, end], fill=color, width=5)
    return c.finish()


def make_feeding_station_front() -> Image.Image:
    c = prop_canvas()
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    trough = (188, 118, 66, 255)
    trough_dark = (118, 72, 45, 255)

    c.rect((136, 326, 376, 402), trough, width=9, radius=22)
    c.rect((154, 336, 358, 374), trough_dark, width=6, radius=16)
    c.line([(154, 348), (358, 348)], fill=wood_light, width=5)
    c.rect((146, 374, 366, 416), trough_dark, outline=(0, 0, 0, 0), width=0, radius=18)
    c.line([(158, 384), (354, 384)], fill=(236, 166, 92, 255), width=6)
    for x in [172, 340]:
        c.rect((x - 12, 404, x + 12, 444), wood, width=5, radius=8)
        c.line([(x + 4, 410), (x + 4, 436)], fill=wood_light, width=2)
    return c.finish()


def make_grooming_station_back() -> Image.Image:
    c = prop_canvas()
    grass = (122, 198, 101, 255)
    grass_light = (164, 224, 127, 255)
    dirt = (212, 151, 91, 255)
    dirt_light = (238, 184, 112, 255)
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    roof = (218, 111, 70, 255)
    roof_light = (248, 151, 85, 255)
    cream = (255, 232, 178, 255)
    straw = (238, 197, 100, 255)

    draw_shadow(c, 256, 444, 300, 34)
    c.ellipse((88, 250, 424, 444), grass, outline=(0, 0, 0, 0), width=0)
    c.ellipse((122, 270, 390, 414), grass_light, outline=(0, 0, 0, 0), width=0)
    c.poly([(152, 420), (360, 420), (330, 292), (182, 292)], dirt, outline=(0, 0, 0, 0), width=0)
    c.poly([(178, 398), (334, 398), (310, 312), (202, 312)], dirt_light, outline=(0, 0, 0, 0), width=0)

    c.rect((132, 150, 380, 300), cream, width=7, radius=24)
    c.rect((152, 170, 360, 264), (255, 241, 202, 255), outline=(0, 0, 0, 0), width=0, radius=18)
    c.poly([(92, 154), (156, 88), (356, 88), (420, 154), (394, 190), (118, 190)], roof, COLORS["outline"], 9)
    c.poly([(158, 88), (356, 88), (394, 154), (118, 154)], roof_light, outline=(0, 0, 0, 0), width=0)
    c.line([(124, 156), (388, 156)], fill=(151, 76, 52, 255), width=6)

    for x in [120, 188, 256, 324, 392]:
        c.rect((x - 13, 178, x + 13, 386), wood, width=6, radius=11)
        c.line([(x + 5, 202), (x + 5, 362)], fill=wood_light, width=2)
    c.rect((106, 226, 406, 260), wood, width=7, radius=16)
    c.line([(122, 238), (390, 238)], fill=wood_light, width=4)

    for start, end, color in [
        ((128, 392), (172, 366), straw),
        ((214, 402), (248, 372), (255, 219, 112, 255)),
        ((312, 398), (280, 370), straw),
        ((354, 388), (390, 366), (255, 219, 112, 255)),
    ]:
        c.line([start, end], fill=color, width=5)
    return c.finish()


def make_grooming_station_front() -> Image.Image:
    c = prop_canvas()
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    bucket = (104, 183, 212, 255)
    towel = (255, 158, 177, 255)

    c.rect((92, 312, 150, 394), (184, 111, 65, 235), width=6, radius=14)
    c.rect((362, 312, 420, 394), (184, 111, 65, 235), width=6, radius=14)
    c.line([(116, 310), (178, 382)], fill=wood_dark, width=12)
    c.line([(120, 306), (182, 376)], fill=wood, width=8)
    c.line([(396, 310), (334, 382)], fill=wood_dark, width=12)
    c.line([(392, 306), (330, 376)], fill=wood, width=8)

    for x in [112, 400]:
        c.rect((x - 12, 294, x + 12, 420), wood, width=5, radius=10)
        c.line([(x + 4, 304), (x + 4, 404)], fill=wood_light, width=2)
    c.rect((118, 372, 394, 410), wood, width=7, radius=17)
    c.line([(136, 386), (376, 386)], fill=wood_light, width=4)

    c.arc((116, 284, 176, 342), 200, 350, fill=towel, width=9)
    c.line([(128, 308), (166, 308)], fill=(255, 205, 216, 255), width=4)
    c.rect((350, 342, 404, 402), bucket, width=6, radius=16)
    c.ellipse((358, 330, 396, 354), (147, 220, 238, 255), width=4)
    c.line([(354, 328), (332, 298)], fill=wood_dark, width=7)
    c.line([(358, 326), (336, 296)], fill=wood_light, width=4)
    c.rect((320, 288, 350, 310), (255, 211, 96, 255), width=5, radius=9)
    return c.finish()


def make_feed_cart() -> Image.Image:
    c = prop_canvas()
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    sack = (248, 206, 119, 255)
    grain = (247, 207, 119, 255)
    wheel = (102, 67, 47, 255)

    draw_shadow(c, 256, 424, 280, 30)
    c.rect((116, 216, 396, 360), wood, width=10, radius=30)
    c.rect((138, 236, 374, 310), wood_light, outline=(0, 0, 0, 0), width=0, radius=20)
    c.line([(142, 320), (370, 320)], fill=wood_dark, width=7)
    c.rect((162, 146, 230, 258), sack, width=7, radius=24)
    c.ellipse((172, 124, 220, 166), (232, 176, 91, 255), width=6)
    c.line([(178, 198), (214, 210)], fill=(176, 104, 54, 120), width=4)
    c.rect((252, 152, 340, 250), (255, 220, 132, 255), width=7, radius=24)
    c.ellipse((268, 134, 324, 178), grain, width=6)
    draw_feed_bits(c, 302, 204)
    c.line([(106, 248), (62, 204)], fill=wood_dark, width=9)
    c.line([(396, 248), (450, 204)], fill=wood_dark, width=9)
    for x in [164, 348]:
        c.ellipse((x - 34, 344, x + 34, 412), wheel, width=7)
        c.ellipse((x - 12, 366, x + 12, 390), wood_light, width=4)
    return c.finish()


def make_hub_grooming_stalls() -> Image.Image:
    c = prop_canvas()
    grass = (118, 196, 100, 255)
    grass_light = (162, 222, 126, 255)
    grass_dark = (78, 151, 80, 255)
    dirt = (210, 151, 92, 255)
    dirt_light = (241, 191, 126, 255)
    dirt_dark = (151, 92, 58, 255)
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    roof = (205, 103, 66, 255)
    roof_light = (239, 142, 82, 255)
    roof_dark = (145, 67, 50, 255)
    cream = (255, 239, 196, 255)
    straw = (238, 197, 100, 255)
    bucket = (104, 183, 212, 255)
    bucket_light = (147, 220, 238, 255)
    towel = (255, 158, 177, 255)

    draw_shadow(c, 256, 438, 386, 44)

    # A covered grooming bay: readable as a small stall, while staying clear behind the animals.
    c.ellipse((44, 206, 468, 446), grass, outline=(0, 0, 0, 0), width=0)
    c.ellipse((80, 226, 432, 416), grass_light, outline=(0, 0, 0, 0), width=0)
    c.arc((74, 236, 438, 426), 14, 168, fill=grass_dark, width=6)
    c.ellipse((106, 274, 406, 424), (dirt[0], dirt[1], dirt[2], 160), outline=(0, 0, 0, 0), width=0)
    c.ellipse((148, 300, 364, 398), (dirt_light[0], dirt_light[1], dirt_light[2], 135), outline=(0, 0, 0, 0), width=0)
    c.poly([(156, 418), (356, 418), (322, 298), (190, 298)], (232, 169, 101, 190), outline=(0, 0, 0, 0), width=0)

    # Roof and back wall make this read as a cozy horse-stall-inspired care station.
    c.rect((116, 118, 396, 246), cream, width=8, radius=20)
    c.rect((132, 138, 380, 218), (255, 226, 168, 255), outline=(0, 0, 0, 0), width=0, radius=14)
    c.line([(132, 218), (380, 218)], fill=(213, 151, 91, 160), width=5)
    c.poly([(64, 126), (132, 58), (380, 58), (448, 126), (424, 166), (88, 166)], roof, COLORS["outline"], 9)
    c.poly([(132, 58), (380, 58), (424, 126), (88, 126)], roof_light, outline=(0, 0, 0, 0), width=0)
    c.line([(94, 128), (418, 128)], fill=roof_dark, width=7)
    c.line([(132, 70), (92, 122)], fill=(255, 174, 103, 190), width=5)
    c.line([(380, 70), (420, 122)], fill=roof_dark, width=5)
    c.rect((76, 154, 436, 194), wood, width=8, radius=18)
    c.line([(96, 168), (416, 168)], fill=wood_light, width=4)
    c.rect((206, 86, 306, 134), cream, width=6, radius=18)
    c.line([(228, 116), (282, 116)], fill=wood_dark, width=12)
    c.line([(230, 112), (280, 112)], fill=wood_light, width=6)
    c.rect((218, 98, 250, 122), (255, 207, 96, 255), width=5, radius=11)
    for bristle_x in [222, 232, 242, 250]:
        c.line([(bristle_x, 122), (bristle_x - 3, 132)], fill=wood_dark, width=3)

    # Stall posts and partial side walls keep the front open and inviting.
    for x, y, h in [(72, 170, 214), (156, 154, 220), (256, 150, 222), (356, 154, 220), (440, 170, 214)]:
        c.rect((x - 15, y, x + 15, y + h), wood, width=7, radius=13)
        c.line([(x - 4, y + 24), (x - 4, y + h - 22)], fill=wood_dark, width=3)
        c.line([(x + 6, y + 28), (x + 6, y + h - 30)], fill=wood_light, width=2)
        c.rect((x - 23, y - 18, x + 23, y + 10), wood_dark, width=6, radius=9)

    c.rect((88, 236, 424, 274), wood, width=8, radius=18)
    c.line([(104, 249), (408, 249)], fill=wood_light, width=4)
    c.rect((82, 278, 156, 352), (184, 111, 65, 235), width=7, radius=16)
    c.rect((356, 278, 430, 352), (184, 111, 65, 235), width=7, radius=16)
    for plank_y in [300, 326]:
        c.line([(96, plank_y), (144, plank_y)], fill=wood_light, width=4)
        c.line([(368, plank_y), (416, plank_y)], fill=wood_light, width=4)

    # Side rails frame an inviting open entrance where brushing happens.
    c.line([(82, 278), (150, 360)], fill=wood_dark, width=13)
    c.line([(88, 274), (154, 352)], fill=wood, width=9)
    c.line([(430, 278), (362, 360)], fill=wood_dark, width=13)
    c.line([(424, 274), (358, 352)], fill=wood, width=9)
    c.rect((112, 300, 142, 394), wood, width=7, radius=12)
    c.rect((370, 300, 400, 394), wood, width=7, radius=12)

    # Tidy care details keep the brushing purpose obvious without clutter.
    c.arc((66, 292, 144, 354), 200, 350, fill=towel, width=10)
    c.line([(78, 316), (132, 316)], fill=(255, 205, 216, 255), width=5)

    c.arc((382, 284, 446, 344), 196, 344, fill=wood_dark, width=6)
    c.rect((386, 312, 442, 376), bucket, width=7, radius=16)
    c.ellipse((394, 300, 434, 326), bucket_light, width=5)
    c.line([(406, 326), (426, 368)], fill=(60, 128, 158, 150), width=4)
    c.line([(398, 292), (372, 258)], fill=wood_dark, width=8)
    c.line([(402, 290), (376, 256)], fill=wood_light, width=4)
    c.rect((358, 246, 390, 270), (255, 211, 96, 255), width=5, radius=10)

    for start, end, color in [
        ((102, 388), (154, 356), straw),
        ((188, 396), (226, 368), (255, 219, 112, 255)),
        ((300, 392), (274, 360), straw),
        ((356, 386), (404, 364), (255, 219, 112, 255)),
    ]:
        c.line([start, end], fill=color, width=5)

    for x, y in [(174, 300), (332, 292), (214, 366)]:
        c.line([(x - 10, y), (x + 10, y)], fill=(255, 245, 168, 210), width=3)
        c.line([(x, y - 10), (x, y + 10)], fill=(255, 245, 168, 210), width=3)
    return c.finish()


def make_hub_animal_pen_front() -> Image.Image:
    c = prop_canvas()
    wood = (221, 149, 84, 255)
    wood_light = (248, 188, 112, 255)
    wood_dark = (136, 83, 51, 255)
    # Keep the foreground readable as a short, low rail. Tall posts and a
    # second enclosure hide the building and animal sprites behind it.
    c.rect((62, 350, 450, 392), wood, width=8, radius=18)
    c.line([(78, 364), (434, 364)], fill=wood_light, width=4)
    c.rect((94, 408, 418, 436), wood_dark, outline=(0, 0, 0, 0), width=0, radius=14)
    for x in [92, 256, 420]:
        c.rect((x - 12, 338, x + 12, 424), wood, width=6, radius=10)
        c.line([(x + 4, 350), (x + 4, 410)], fill=wood_light, width=2)
    return c.finish()


def make_decoration(kind: str) -> Image.Image:
    c = prop_canvas()
    if kind == "flower_path":
        c.poly([(160, 118), (352, 118), (426, 420), (86, 420)], (213, 151, 90, 255), COLORS["outline"], 8)
        for x, y, fill in [
            (126, 300, COLORS["pink"]),
            (178, 244, COLORS["yellow"]),
            (346, 250, COLORS["purple"]),
            (386, 322, COLORS["blue"]),
            (250, 354, (255, 170, 126, 255)),
        ]:
            c.line([(x, y + 42), (x, y + 8)], fill=COLORS["leaf"], width=5)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 20
                py = y + math.sin(math.radians(angle)) * 14
                c.ellipse((px - 13, py - 10, px + 13, py + 10), fill, width=3)
            c.ellipse((x - 8, y - 8, x + 8, y + 8), COLORS["yellow"], width=2)
    elif kind == "painted_fence":
        for x in [82, 168, 254, 340, 426]:
            c.rect((x - 19, 142, x + 19, 392), (236, 189, 125, 255), width=7, radius=14)
        c.rect((42, 198, 470, 244), (222, 151, 87, 255), width=7, radius=18)
        c.rect((42, 308, 470, 354), (222, 151, 87, 255), width=7, radius=18)
        for x, y, color in [(122, 260, COLORS["pink"]), (224, 280, COLORS["yellow"]), (326, 262, COLORS["blue"]), (412, 286, COLORS["purple"])]:
            c.line([(x, y + 38), (x, y + 8)], fill=COLORS["leaf"], width=5)
            c.ellipse((x - 20, y - 14, x + 20, y + 14), color, width=4)
            c.ellipse((x - 7, y - 7, x + 7, y + 7), COLORS["yellow"], width=2)
    elif kind == "hay_stack":
        paste_center(c, make_hay_bale(), 196, 306, 210)
        paste_center(c, make_hay_bale(), 318, 326, 190)
        paste_center(c, make_hay_bale(), 260, 214, 180)
    elif kind == "windmill":
        _draw_windmill_base(c, season="")
    elif kind == "windmill_spring":
        _draw_windmill_base(c, season="spring")
    elif kind == "windmill_summer":
        _draw_windmill_base(c, season="summer")
    elif kind == "windmill_fall":
        _draw_windmill_base(c, season="fall")
    elif kind == "windmill_winter":
        _draw_windmill_base(c, season="winter")
    elif kind == "duck_pond":
        draw_shadow(c, 256, 394, 320, 32)
        c.ellipse((84, 220, 428, 404), (119, 202, 236, 255), width=10)
        c.ellipse((132, 246, 380, 356), (153, 224, 248, 255), outline=(0, 0, 0, 0), width=0)
        for x, y in [(150, 380), (370, 372)]:
            c.line([(x, y), (x, y - 60)], fill=COLORS["leaf"], width=7)
            c.ellipse((x - 28, y - 54, x + 24, y - 16), COLORS["leaf_light"], width=4)
    elif kind == "orchard_tree":
        draw_shadow(c, 256, 430, 250, 32)
        c.rect((226, 250, 286, 428), (133, 82, 53, 255), width=7, radius=18)
        for x, y, r, color in [
            (182, 220, 78, COLORS["leaf_light"]),
            (258, 162, 96, (126, 216, 104, 255)),
            (340, 220, 76, (158, 225, 111, 255)),
            (260, 266, 88, COLORS["leaf_light"]),
        ]:
            c.ellipse((x - r, y - r, x + r, y + r), color, width=8)
        for x, y, color in [(220, 178, COLORS["pink"]), (306, 192, COLORS["yellow"]), (266, 258, COLORS["blue"])]:
            c.ellipse((x - 16, y - 16, x + 16, y + 16), color, width=4)
    elif kind == "clean_barn_sign":
        draw_shadow(c, 256, 392, 250, 30)
        c.rect((136, 190, 376, 350), (255, 244, 204, 255), width=9, radius=34)
        c.poly([(116, 196), (256, 104), (396, 196)], COLORS["barn_red"], COLORS["outline"], 9)
        c.line([(178, 262), (226, 310), (334, 222)], fill=COLORS["leaf"], width=16)
        draw_small_stars(c, [(142, 154), (386, 154), (384, 336)])
    return c.finish()


def _draw_windmill_base(c: Canvas, season: str = "") -> None:
    draw_shadow(c, 256, 438, 190, 28)
    body_fill = (238, 218, 180, 255)
    roof_fill = COLORS["barn_red"]
    sail_fill = (255, 248, 218, 255)
    accent_fill = COLORS["blue"]
    tower_fill = (213, 184, 136, 255)
    tower_highlight = (248, 233, 192, 255)
    if season == "spring":
        body_fill = (236, 226, 190, 255)
        roof_fill = (230, 120, 136, 255)
        sail_fill = (250, 252, 230, 255)
        accent_fill = (143, 214, 126, 255)
    elif season == "summer":
        body_fill = (240, 220, 164, 255)
        roof_fill = (214, 112, 64, 255)
        sail_fill = (255, 248, 210, 255)
        accent_fill = (106, 183, 232, 255)
    elif season == "fall":
        body_fill = (224, 200, 154, 255)
        roof_fill = (203, 104, 60, 255)
        sail_fill = (255, 244, 210, 255)
        accent_fill = (246, 168, 88, 255)
    elif season == "winter":
        body_fill = (227, 239, 246, 255)
        roof_fill = (120, 164, 214, 255)
        sail_fill = (250, 252, 255, 255)
        accent_fill = (196, 224, 245, 255)
        tower_highlight = (250, 252, 255, 255)

    c.rect((214, 168, 298, 438), body_fill, width=9, radius=26)
    c.line([(220, 182), (220, 418)], fill=tower_highlight, width=6)
    c.poly([(198, 176), (256, 86), (314, 176)], roof_fill, COLORS["outline"], 9)
    c.ellipse((224, 208, 288, 274), accent_fill, width=6)
    for angle in [0, math.pi / 2, math.pi, math.pi * 1.5]:
        end = (256 + math.cos(angle) * 126, 164 + math.sin(angle) * 126)
        c.line([(256, 164), end], fill=COLORS["outline"], width=8)
        c.ellipse((end[0] - 22, end[1] - 14, end[0] + 22, end[1] + 14), sail_fill, width=5)
    c.ellipse((240, 148, 272, 180), COLORS["yellow"], width=5)

    if season == "spring":
        for x, y in [(160, 386), (186, 404), (334, 398), (360, 382)]:
            c.line([(x, y), (x, y - 34)], fill=COLORS["leaf"], width=4)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 8
                py = y + math.sin(math.radians(angle)) * 6
                c.ellipse((px - 5, py - 4, px + 5, py + 4), COLORS["pink"], width=2)
            c.ellipse((x - 3, y - 3, x + 3, y + 3), COLORS["yellow"], width=1)
    elif season == "summer":
        for x, y in [(182, 392), (340, 396)]:
            c.line([(x, y), (x, y - 20)], fill=COLORS["leaf"], width=5)
            c.ellipse((x - 12, y - 12, x + 12, y + 12), (255, 230, 145, 255), width=3)
            c.ellipse((x - 4, y - 4, x + 4, y + 4), COLORS["orange"], width=1)
    elif season == "fall":
        for x, y in [(170, 390), (196, 408), (322, 406), (348, 392)]:
            c.poly([(x, y - 18), (x + 12, y - 2), (x, y + 16), (x - 12, y - 2)], (248, 173, 82, 255), COLORS["outline"], 4)
    elif season == "winter":
        c.poly([(206, 166), (256, 116), (306, 166)], (248, 252, 255, 255), COLORS["outline"], 4)
        for x, y in [(174, 386), (350, 384)]:
            c.ellipse((x - 14, y - 8, x + 14, y + 8), (250, 252, 255, 255), width=3)
        for x, y in [(148, 406), (360, 404)]:
            c.line([(x, y), (x, y - 28)], fill=(250, 252, 255, 220), width=4)


def generate_props() -> None:
    save(make_egg(False), "props/egg.png")
    save(make_egg(True), "props/golden_egg.png")
    save(make_basket(), "props/egg_basket.png")
    save(make_basket_front(), "props/egg_basket_front.png")
    save(make_bucket(), "props/milk_bucket.png")
    save(make_bucket_front(), "props/milk_bucket_front.png")
    save(make_feed_bag(), "props/feed_bag.png")
    save(make_feed_scoop(), "props/feed_scoop.png")
    save(make_feed_pour(), "props/feed_pour.png")
    save(make_brush(), "props/grooming_brush.png")
    save(make_watering_can(), "props/watering_can.png")
    save(make_hay_bale(), "props/hay_bale.png")
    save(make_milking_stanchion_frame(), "props/milking_stanchion_frame.png")
    save(make_chicken_nest("wood_box"), "props/chicken_nest_wood_box.png")
    save(make_chicken_nest("woven_bowl"), "props/chicken_nest_woven_bowl.png")
    save(make_chicken_nest("hay_pocket"), "props/chicken_nest_hay_pocket.png")
    save(make_cow_milking_stanchion(), "props/cow_milking_stanchion.png")
    save(make_hub_feed_pen(), "props/hub_feed_pen.png")
    save(make_hub_feed_trough_front(), "props/hub_feed_trough_front.png")
    save(make_feeding_station_back(), "props/feeding_station_back.png")
    save(make_feeding_station_front(), "props/feeding_station_front.png")
    save(make_feed_pile(), "props/feed_pile.png")
    save(make_grooming_station_back(), "props/grooming_station_back.png")
    save(make_grooming_station_front(), "props/grooming_station_front.png")
    save(make_feed_cart(), "props/feed_cart.png")
    save(make_hub_grooming_stalls(), "props/hub_grooming_stalls.png")
    save(make_hub_animal_pen_front(), "props/hub_animal_pen_front.png")
    for kind in ["cloud", "tree", "bush", "fence_panel", "dirt_path", "chicken_coop", "barn"]:
        save(make_simple_prop(kind), f"props/{kind}.png")
    for kind in ["flower_path", "painted_fence", "hay_stack", "windmill", "windmill_spring", "windmill_summer", "windmill_fall", "windmill_winter", "duck_pond", "orchard_tree", "clean_barn_sign"]:
        save(make_decoration(kind), f"props/decoration_{kind}.png")


def make_plot_tile() -> Image.Image:
    c = prop_canvas()
    soil = (158, 94, 55, 255)
    soil_light = (202, 133, 74, 255)
    soil_dark = (104, 66, 45, 255)
    wood = (210, 142, 79, 255)
    wood_light = (244, 181, 103, 255)

    draw_shadow(c, 256, 386, 344, 42)
    c.ellipse((68, 182, 444, 388), soil_dark, width=11)
    c.ellipse((92, 168, 420, 352), soil, width=10)
    c.ellipse((126, 194, 386, 326), soil_light, outline=(0, 0, 0, 0), width=0)
    for y, inset in [(222, 30), (262, 22), (304, 38)]:
        c.arc((104 + inset, y - 42, 408 - inset, y + 40), 188, 352, fill=soil_dark, width=8)
        c.arc((126 + inset, y - 34, 386 - inset, y + 28), 196, 340, fill=(232, 167, 89, 160), width=4)
    c.rect((78, 338, 434, 378), wood, width=9, radius=20)
    c.line([(104, 348), (406, 348)], fill=wood_light, width=5)
    for x in [146, 256, 366]:
        c.line([(x, 338), (x - 8, 376)], fill=(137, 84, 55, 255), width=5)
    return c.finish()


def make_wet_soil_overlay() -> Image.Image:
    c = prop_canvas()
    water = (93, 178, 221, 122)
    water_light = (206, 246, 255, 132)
    c.ellipse((104, 200, 408, 338), water, outline=(0, 0, 0, 0), width=0)
    for y, inset in [(236, 36), (276, 54), (310, 78)]:
        c.arc((122 + inset, y - 30, 390 - inset, y + 26), 190, 350, fill=water_light, width=5)
    for x, y, r in [(178, 252, 9), (272, 226, 8), (334, 282, 7)]:
        c.ellipse((x - r, y - r, x + r, y + r), water_light, outline=(0, 0, 0, 0), width=0)
    return c.finish()


def make_growth(stage: str) -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 408, 170, 28)
    if stage == "seed":
        c.ellipse((214, 246, 248, 286), (116, 74, 48, 255), width=5)
        c.ellipse((268, 238, 302, 278), (116, 74, 48, 255), width=5)
    elif stage == "sprout":
        c.line([(256, 336), (256, 246)], fill=(72, 151, 75, 255), width=12)
        c.ellipse((194, 244, 264, 300), (109, 205, 94, 255), width=7)
        c.ellipse((250, 218, 326, 282), (129, 222, 104, 255), width=7)
    elif stage == "plant_small":
        c.line([(256, 372), (256, 210)], fill=(72, 151, 75, 255), width=14)
        for x, y in [(206, 294), (304, 282), (218, 220), (294, 214)]:
            c.ellipse((x - 52, y - 28, x + 52, y + 28), (111, 204, 93, 255), width=7)
    elif stage == "plant_growing":
        c.line([(256, 388), (256, 170)], fill=(72, 151, 75, 255), width=16)
        for x, y in [(198, 306), (320, 292), (206, 222), (314, 204), (256, 150)]:
            c.ellipse((x - 58, y - 34, x + 58, y + 34), (117, 211, 94, 255), width=8)
    elif stage == "harvest_ready":
        c.line([(256, 390), (256, 180)], fill=(72, 151, 75, 255), width=16)
        c.ellipse((176, 222, 336, 366), COLORS["orange"], width=9)
        c.line([(256, 180), (238, 154)], fill=(72, 151, 75, 255), width=10)
    elif stage == "harvested":
        c.line([(224, 372), (256, 320), (290, 372)], fill=(120, 86, 55, 255), width=13)
        c.ellipse((186, 350, 326, 408), (170, 105, 61, 255), width=7)
    return c.finish()


def make_vegetable(kind: str) -> Image.Image:
    c = prop_canvas()
    draw_shadow(c, 256, 418, 190, 28)
    if kind == "carrot":
        c.poly([(228, 154), (308, 154), (266, 400)], (244, 136, 54, 255), COLORS["outline"], 9)
        c.ellipse((190, 104, 254, 172), COLORS["leaf_light"], width=6)
        c.ellipse((258, 96, 330, 174), COLORS["leaf_light"], width=6)
    elif kind == "turnip":
        c.ellipse((168, 166, 344, 364), (238, 217, 245, 255), width=10)
        c.poly([(224, 340), (256, 430), (290, 340)], (208, 165, 215, 255), COLORS["outline"], 7)
        c.ellipse((198, 98, 260, 170), COLORS["leaf_light"], width=6)
        c.ellipse((252, 86, 322, 170), COLORS["leaf_light"], width=6)
    elif kind == "corn":
        c.ellipse((190, 108, 322, 390), (255, 218, 77, 255), width=9)
        c.poly([(172, 250), (108, 406), (256, 326)], (112, 188, 86, 255), COLORS["outline"], 7)
        c.poly([(340, 250), (404, 406), (256, 326)], (112, 188, 86, 255), COLORS["outline"], 7)
    elif kind == "tomato":
        c.ellipse((156, 162, 356, 360), (240, 86, 72, 255), width=10)
        draw_star(c, 256, 160, 44, COLORS["leaf_light"])
    elif kind == "strawberry":
        c.poly([(164, 178), (348, 178), (256, 394)], (242, 83, 100, 255), COLORS["outline"], 10)
        draw_star(c, 256, 164, 44, COLORS["leaf_light"])
        for x, y in [(220, 230), (270, 254), (246, 310), (300, 318)]:
            c.ellipse((x - 7, y - 7, x + 7, y + 7), (255, 239, 138, 255), width=2)
    elif kind == "pumpkin":
        c.ellipse((132, 172, 380, 372), COLORS["orange"], width=10)
        c.arc((176, 178, 288, 368), 80, 280, fill=(212, 103, 51, 255), width=7)
        c.arc((224, 178, 336, 368), 260, 100, fill=(212, 103, 51, 255), width=7)
        c.line([(256, 178), (278, 126)], fill=(89, 137, 64, 255), width=12)
    elif kind == "apple":
        c.ellipse((148, 166, 276, 354), (226, 74, 72, 255), width=10)
        c.ellipse((236, 166, 364, 354), (226, 74, 72, 255), width=10)
        c.line([(258, 172), (278, 116)], fill=(110, 72, 47, 255), width=10)
        c.ellipse((278, 116, 342, 168), COLORS["leaf_light"], width=6)
    elif kind == "sunflower":
        for i in range(12):
            a = i * math.pi / 6
            x = 256 + math.cos(a) * 86
            y = 212 + math.sin(a) * 86
            c.ellipse((x - 38, y - 24, x + 38, y + 24), COLORS["yellow"], width=6)
        c.ellipse((206, 162, 306, 262), (127, 76, 47, 255), width=8)
        c.line([(256, 262), (256, 410)], fill=(83, 154, 75, 255), width=12)
    return c.finish()


def generate_garden() -> None:
    save(make_plot_tile(), "garden/plot_tile.png")
    save(make_wet_soil_overlay(), "garden/wet_soil_overlay.png")
    for stage in ["seed", "sprout", "plant_small", "plant_growing", "harvest_ready", "harvested"]:
        save(make_growth(stage), f"garden/{stage}.png")
    for vegetable in ["carrot", "turnip", "corn", "tomato", "strawberry", "pumpkin", "apple", "sunflower"]:
        save(make_vegetable(vegetable), f"garden/{vegetable}.png")


def make_effect(kind: str) -> Image.Image:
    c = Canvas(512, 512)
    if kind == "sparkle":
        draw_star(c, 256, 256, 112, (255, 241, 126, 255))
        draw_star(c, 130, 150, 42, (159, 226, 255, 255))
        draw_star(c, 380, 344, 42, (255, 170, 203, 255))
    elif kind == "star":
        draw_star(c, 256, 256, 150, COLORS["yellow"])
    elif kind == "touch_indicator":
        for r, a in [(154, 70), (104, 110), (52, 180)]:
            c.ellipse((256 - r, 256 - r, 256 + r, 256 + r), (255, 255, 255, a), outline=(80, 54, 42, min(180, a + 40)), width=6)
    elif kind == "success_glow":
        for r, a in [(210, 30), (160, 50), (110, 75), (60, 115)]:
            c.ellipse((256 - r, 256 - r, 256 + r, 256 + r), (255, 244, 136, a), outline=(0, 0, 0, 0), width=0)
    elif kind == "bounce_indicator":
        c.arc((120, 192, 392, 426), 200, 340, fill=COLORS["outline"], width=12)
        c.poly([(350, 286), (418, 286), (388, 350)], COLORS["yellow"], COLORS["outline"], 8)
    elif kind == "reward_burst":
        for i in range(16):
            a = i * math.pi / 8
            c.line([(256, 256), (256 + math.cos(a) * 210, 256 + math.sin(a) * 210)], fill=COLORS["yellow"], width=8)
        draw_star(c, 256, 256, 72, (255, 169, 201, 255))
    elif kind == "water_drop":
        for x, y, size, alpha in [(238, 180, 72, 255), (318, 252, 56, 232), (192, 298, 46, 218)]:
            c.poly(
                [(x, y - size), (x + size * 0.55, y + size * 0.18), (x + size * 0.36, y + size * 0.8), (x, y + size), (x - size * 0.36, y + size * 0.8), (x - size * 0.55, y + size * 0.18)],
                (94, 185, 237, alpha),
                COLORS["outline"],
                8,
            )
            c.ellipse((x - size * 0.18, y - size * 0.12, x + size * 0.14, y + size * 0.26), rgba(COLORS["white"], 120), outline=(0, 0, 0, 0), width=0)
    elif kind == "dirt_smudge":
        for x, y, rx, ry in [(202, 228, 60, 34), (286, 260, 52, 30), (248, 322, 70, 34), (330, 196, 38, 24)]:
            c.ellipse((x - rx, y - ry, x + rx, y + ry), (118, 77, 49, 178), outline=(85, 55, 39, 190), width=4)
        for x, y in [(196, 314), (314, 286), (262, 206)]:
            c.ellipse((x - 12, y - 8, x + 12, y + 8), (85, 55, 39, 170), outline=(0, 0, 0, 0), width=0)
    elif kind == "clean_sparkle":
        for x, y, r in [(256, 226, 86), (164, 310, 34), (354, 316, 40)]:
            draw_star(c, x, y, r, (255, 245, 142, 255))
        c.ellipse((184, 192, 328, 342), (255, 255, 255, 65), outline=(0, 0, 0, 0), width=0)
    return c.finish()


def generate_effects() -> None:
    for kind in ["sparkle", "star", "touch_indicator", "success_glow", "bounce_indicator", "reward_burst", "water_drop", "dirt_smudge", "clean_sparkle"]:
        save(make_effect(kind), f"effects/{kind}.png")
    frames = [make_effect("sparkle"), make_effect("star"), make_effect("success_glow"), make_effect("reward_burst")]
    sheet = Image.new("RGBA", (512 * len(frames), 512), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (512 * index, 0))
    save(sheet, "effects/confetti_reward_sheet.png")


def make_ui_button(kind: str) -> Image.Image:
    c = Canvas(512, 512)
    c.rect((80, 104, 432, 408), (255, 238, 170, 255), width=12, radius=86)
    c.rect((104, 128, 408, 384), (255, 250, 210, 255), outline=(0, 0, 0, 0), width=0, radius=68)
    if kind == "play_button":
        c.poly([(220, 176), (220, 336), (352, 256)], COLORS["leaf"], COLORS["outline"], 11)
    elif kind == "back_button":
        c.line([(324, 170), (210, 256), (324, 342)], width=24)
    elif kind == "home_button":
        c.poly([(160, 256), (256, 166), (352, 256), (330, 256), (330, 350), (182, 350), (182, 256)], COLORS["barn_red"], COLORS["outline"], 11)
    elif kind == "pause_button":
        c.rect((184, 176, 238, 336), COLORS["blue"], width=9, radius=18)
        c.rect((274, 176, 328, 336), COLORS["blue"], width=9, radius=18)
    elif kind == "settings_button":
        c.ellipse((98, 98, 414, 414), (118, 192, 216, 255), width=12)
        c.ellipse((128, 128, 384, 384), (171, 226, 235, 255), outline=(0, 0, 0, 0), width=0)
        for i in range(8):
            a = i * math.pi / 4
            x1 = 256 + math.cos(a) * 64
            y1 = 256 + math.sin(a) * 64
            x2 = 256 + math.cos(a) * 112
            y2 = 256 + math.sin(a) * 112
            c.line([(x1, y1), (x2, y2)], fill=COLORS["outline"], width=22)
            c.line([(x1, y1), (x2, y2)], fill=(255, 236, 171, 255), width=13)
        c.ellipse((170, 170, 342, 342), (255, 230, 149, 255), width=11)
        c.ellipse((216, 216, 296, 296), (255, 250, 210, 255), width=8)
    return c.finish()


def make_ui_icon(kind: str) -> Image.Image:
    c = Canvas(160, 160)
    if kind == "play_icon":
        c.ellipse((20, 20, 140, 140), (255, 235, 139, 255), width=6)
        c.poly([(62, 44), (62, 116), (122, 80)], COLORS["leaf"], COLORS["outline"], 7)
    elif kind == "next_day_icon":
        c.ellipse((34, 22, 126, 138), (255, 235, 139, 255), width=7)
        c.ellipse((64, 10, 146, 116), (0, 0, 0, 0), outline=(0, 0, 0, 0), width=0)
        for x, y, r in [(114, 36, 8), (128, 74, 6), (102, 112, 5)]:
            draw_star(c, x, y, r, COLORS["white"])
    return c.finish()


def make_title_banner() -> Image.Image:
    c = Canvas(1280, 300)
    wood = (202, 126, 70, 255)
    wood_light = (244, 181, 103, 255)
    wood_dark = (120, 73, 49, 255)
    cream = (255, 237, 184, 255)
    cream_light = (255, 249, 217, 255)

    draw_shadow(c, 640, 262, 980, 42)
    c.rect((118, 88, 1162, 240), wood, width=12, radius=52)
    c.rect((160, 112, 1120, 216), cream, width=8, radius=38)
    c.rect((188, 128, 1092, 168), cream_light, outline=(0, 0, 0, 0), width=0, radius=20)
    c.line([(188, 206), (1094, 204)], fill=(225, 166, 92, 160), width=6)

    for x in [166, 1114]:
        c.rect((x - 26, 42, x + 26, 258), wood_dark, width=7, radius=18)
        c.line([(x - 8, 64), (x - 8, 238)], fill=wood_light, width=5)
    c.line([(232, 102), (1048, 102)], fill=wood_light, width=7)
    c.line([(232, 232), (1048, 232)], fill=wood_dark, width=7)

    for x, y, color in [(246, 62, COLORS["pink"]), (316, 58, COLORS["yellow"]), (1004, 62, COLORS["blue"]), (1072, 58, COLORS["pink"])]:
        c.line([(x, y + 34), (x, y + 8)], fill=COLORS["leaf"], width=5)
        for angle in range(0, 360, 72):
            px = x + math.cos(math.radians(angle)) * 15
            py = y + math.sin(math.radians(angle)) * 10
            c.ellipse((px - 9, py - 7, px + 9, py + 7), color, width=2)
        c.ellipse((x - 5, y - 5, x + 5, y + 5), COLORS["yellow"], width=1)
    return c.finish()


def make_play_button_polished() -> Image.Image:
    c = Canvas(640, 230)
    green = (104, 190, 91, 255)
    green_light = (151, 224, 112, 255)
    green_dark = (65, 139, 75, 255)
    cream = (255, 239, 178, 255)
    draw_shadow(c, 320, 202, 470, 36)
    c.rect((70, 42, 570, 178), green, width=12, radius=68)
    c.rect((104, 64, 536, 120), green_light, outline=(0, 0, 0, 0), width=0, radius=34)
    c.ellipse((98, 60, 222, 184), cream, width=8)
    c.poly([(142, 92), (142, 152), (190, 122)], green_dark, COLORS["outline"], 7)
    c.line([(252, 144), (500, 144)], fill=green_dark, width=7)
    return c.finish()


def make_season_icon(kind: str) -> Image.Image:
    c = Canvas(256, 256)
    if kind == "spring_seedling":
        c.line([(128, 202), (128, 96)], fill=COLORS["leaf"], width=12)
        c.ellipse((54, 100, 136, 170), COLORS["leaf_light"], width=7)
        c.ellipse((122, 74, 208, 150), (120, 216, 102, 255), width=7)
        c.ellipse((82, 196, 174, 226), COLORS["dirt"], width=6)
    elif kind == "summer_sun":
        for angle in range(0, 360, 30):
            x = 128 + math.cos(math.radians(angle)) * 88
            y = 128 + math.sin(math.radians(angle)) * 88
            c.line([(128, 128), (x, y)], fill=COLORS["yellow"], width=13)
        c.ellipse((62, 62, 194, 194), COLORS["yellow"], width=8)
        draw_eye(c, 106, 120, "happy")
        draw_eye(c, 150, 120, "happy")
        draw_smile(c, 128, 146, True)
    elif kind == "fall_leaf":
        c.poly([(128, 40), (202, 92), (174, 184), (128, 222), (82, 184), (54, 92)], COLORS["orange"], COLORS["outline"], 8)
        c.line([(128, 58), (128, 222)], fill=(139, 79, 50, 255), width=9)
        c.line([(128, 132), (78, 98)], fill=(179, 95, 48, 255), width=6)
        c.line([(128, 142), (184, 102)], fill=(179, 95, 48, 255), width=6)
    elif kind == "winter_snowflake":
        c.ellipse((34, 34, 222, 222), (255, 250, 224, 255), width=9)
        c.ellipse((56, 56, 200, 200), (202, 238, 255, 255), outline=(0, 0, 0, 0), width=0)
        for angle in range(0, 180, 30):
            dx = math.cos(math.radians(angle)) * 88
            dy = math.sin(math.radians(angle)) * 88
            c.line([(128 - dx, 128 - dy), (128 + dx, 128 + dy)], fill=COLORS["outline"], width=15)
            c.line([(128 - dx, 128 - dy), (128 + dx, 128 + dy)], fill=(74, 154, 214, 255), width=9)
        for angle in range(0, 360, 60):
            x = 128 + math.cos(math.radians(angle)) * 58
            y = 128 + math.sin(math.radians(angle)) * 58
            c.ellipse((x - 9, y - 9, x + 9, y + 9), COLORS["white"], width=3)
        c.ellipse((104, 104, 152, 152), COLORS["white"], width=5)
    return c.finish()


def make_app_icon_background() -> Image.Image:
    c = Canvas(432, 432, transparent=False)
    sky_top = (151, 222, 246, 255)
    sky_bottom = (198, 241, 246, 255)
    for y in range(432):
        t = y / 431
        color = tuple(int(sky_top[i] * (1 - t) + sky_bottom[i] * t) for i in range(4))
        c.draw.line([(0, c.s(y)), (c.s(432), c.s(y))], fill=color, width=c.s(1))

    # Soft storybook hills give adaptive icon masks a friendly farm silhouette.
    c.ellipse((-82, 170, 286, 420), (128, 197, 105, 255), outline=(0, 0, 0, 0), width=0)
    c.ellipse((132, 158, 520, 424), (108, 179, 101, 255), outline=(0, 0, 0, 0), width=0)
    c.ellipse((-70, 236, 502, 494), (104, 195, 92, 255), outline=(0, 0, 0, 0), width=0)
    c.line([(0, 310), (432, 310)], fill=(91, 160, 82, 120), width=5)

    for x, y, color in [
        (52, 346, COLORS["pink"]),
        (84, 370, COLORS["yellow"]),
        (348, 344, COLORS["yellow"]),
        (384, 374, COLORS["pink"]),
    ]:
        c.line([(x, y + 20), (x, y - 2)], fill=COLORS["leaf"], width=4)
        for angle in range(0, 360, 72):
            px = x + math.cos(math.radians(angle)) * 10
            py = y + math.sin(math.radians(angle)) * 8
            c.ellipse((px - 6, py - 5, px + 6, py + 5), color, width=2)
        c.ellipse((x - 4, y - 4, x + 4, y + 4), COLORS["yellow"], width=1)
    return c.finish()


def make_app_icon_foreground(monochrome: bool = False) -> Image.Image:
    c = Canvas(432, 432)
    outline = (0, 0, 0, 255) if monochrome else COLORS["outline"]
    barn_red = (0, 0, 0, 255) if monochrome else COLORS["barn_red"]
    barn_light = (0, 0, 0, 180) if monochrome else (245, 129, 88, 255)
    cream = (0, 0, 0, 210) if monochrome else COLORS["cream"]
    wood = (0, 0, 0, 220) if monochrome else COLORS["wood"]
    wood_light = (0, 0, 0, 130) if monochrome else (244, 181, 103, 255)
    white = (0, 0, 0, 255) if monochrome else COLORS["white"]
    yellow = (0, 0, 0, 220) if monochrome else COLORS["yellow"]

    draw_shadow(c, 218, 352, 258, 44)
    c.poly([(92, 198), (216, 98), (342, 198)], barn_red, outline, 10)
    c.poly([(126, 190), (216, 120), (306, 190)], barn_light, outline=(0, 0, 0, 0), width=0)
    c.rect((114, 188, 320, 324), cream, outline=outline, width=9, radius=26)
    c.rect((178, 234, 256, 326), wood, outline=outline, width=7, radius=16)
    c.line([(190, 248), (244, 312)], fill=wood_light, width=5)
    c.line([(244, 248), (190, 312)], fill=wood_light, width=5)
    c.rect((130, 214, 168, 252), (0, 0, 0, 160) if monochrome else (128, 202, 226, 255), outline=outline, width=5, radius=9)
    c.rect((266, 214, 304, 252), (0, 0, 0, 160) if monochrome else (128, 202, 226, 255), outline=outline, width=5, radius=9)

    # The chicken is the readable hero shape at launcher size.
    if monochrome:
        chicken = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        d = ImageDraw.Draw(chicken)
        d.ellipse((92, 132, 420, 420), fill=(0, 0, 0, 255))
        d.ellipse((156, 64, 356, 240), fill=(0, 0, 0, 255))
        d.polygon([(350, 164), (438, 194), (350, 224)], fill=(0, 0, 0, 255))
        d.ellipse((198, 18, 242, 82), fill=(0, 0, 0, 255))
        d.ellipse((236, 8, 286, 80), fill=(0, 0, 0, 255))
        d.ellipse((282, 20, 326, 84), fill=(0, 0, 0, 255))
    else:
        chicken = draw_chicken("happy")
    paste_center(c, chicken, 218, 280, 214)

    # A small golden egg reinforces the egg-collecting farm theme without text.
    c.ellipse((294, 294, 356, 374), yellow, outline=outline, width=7)
    c.arc((304, 312, 346, 358), 210, 330, fill=white, width=4)
    return c.finish()


def make_app_icon_legacy() -> Image.Image:
    background = make_app_icon_background()
    foreground = make_app_icon_foreground()
    icon = background.copy()
    icon.alpha_composite(foreground)
    return icon.resize((192, 192), Image.Resampling.LANCZOS)


def generate_ui() -> None:
    for kind in ["play_button", "back_button", "home_button", "pause_button", "settings_button"]:
        save(make_ui_button(kind), f"ui/{kind}.png")
    save(make_title_banner(), "ui/title_banner.png")
    save(make_play_button_polished(), "ui/play_button_polished.png")
    save(make_app_icon_legacy(), "ui/app_icon_192.png")
    save(make_app_icon_foreground(), "ui/app_icon_adaptive_foreground_432.png")
    save(make_app_icon_background(), "ui/app_icon_adaptive_background_432.png")
    save(make_app_icon_foreground(monochrome=True), "ui/app_icon_adaptive_monochrome_432.png")
    for kind in ["play_icon", "next_day_icon"]:
        save(make_ui_icon(kind), f"ui/{kind}.png")
    for kind in ["spring_seedling", "summer_sun", "fall_leaf", "winter_snowflake"]:
        save(make_season_icon(kind), f"ui/season_{kind}.png")
    icon_sources = {
        "progress_egg_icon": make_egg(False),
        "progress_milk_icon": make_bucket(),
        "progress_feed_icon": make_feed_scoop(),
        "progress_brush_icon": make_brush(),
        "progress_garden_icon": make_growth("sprout"),
        "completion_badge": make_effect("star"),
        "reward_star": make_effect("star"),
    }
    for name, img in icon_sources.items():
        save(img.resize((256, 256), Image.Resampling.LANCZOS), f"ui/{name}.png")


def background_base() -> Canvas:
    c = Canvas(1920, 1080, transparent=False)
    c.rect((-20, 620, 1940, 1120), COLORS["grass"], outline=(0, 0, 0, 0), width=0, radius=0)
    c.ellipse((-220, 535, 760, 760), rgba(COLORS["leaf_light"], 90), outline=(0, 0, 0, 0), width=0)
    c.ellipse((820, 555, 2140, 790), rgba(COLORS["leaf_light"], 75), outline=(0, 0, 0, 0), width=0)
    return c


def add_background_details(c: Canvas) -> None:
    for x, y, scale in [(220, 150, 0.55), (590, 110, 0.42), (1540, 170, 0.48)]:
        cloud = make_simple_prop("cloud").resize((int(512 * scale), int(512 * scale)), Image.Resampling.LANCZOS)
        c.image.alpha_composite(cloud.resize((cloud.width * SCALE, cloud.height * SCALE), Image.Resampling.LANCZOS), (c.s(x), c.s(y)))


def paste_asset(c: Canvas, img: Image.Image, x: int, y: int, size: int) -> None:
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    c.image.alpha_composite(resized.resize((size * SCALE, size * SCALE), Image.Resampling.LANCZOS), (c.s(x), c.s(y)))


def make_background(kind: str) -> Image.Image:
    c = background_base()
    add_background_details(c)
    if kind == "farmyard_background":
        sky = (156, 224, 249, 255)
        sky_light = (189, 239, 255, 255)
        grass = (112, 198, 98, 255)
        grass_light = (152, 223, 113, 255)
        grass_dark = (83, 166, 82, 255)
        dirt = (210, 148, 86, 255)
        dirt_light = (229, 171, 103, 255)
        dirt_dark = (160, 98, 61, 255)
        wood = (214, 139, 77, 255)
        wood_light = (244, 181, 102, 255)
        wood_dark = (128, 77, 49, 255)
        cream = (255, 232, 176, 255)
        straw = (239, 199, 99, 255)

        c.rect((0, 0, 1920, 1080), sky, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 0, 1920, 370), sky_light, outline=(0, 0, 0, 0), width=0, radius=0)
        for x, y, size in [(150, 70, 230), (565, 44, 170), (1190, 80, 185), (1570, 52, 220)]:
            paste_asset(c, make_simple_prop("cloud"), x, y, size)

        # Soft distant hills and a low fence give the hub depth without busy detail.
        c.ellipse((-220, 320, 950, 640), rgba((166, 225, 124, 255), 150), outline=(0, 0, 0, 0), width=0)
        c.ellipse((680, 326, 2150, 650), rgba((151, 218, 113, 255), 145), outline=(0, 0, 0, 0), width=0)
        c.rect((0, 442, 1920, 1080), grass, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-260, 512, 790, 766), rgba(grass_light, 95), outline=(0, 0, 0, 0), width=0)
        c.ellipse((980, 508, 2220, 790), rgba(grass_light, 105), outline=(0, 0, 0, 0), width=0)
        c.ellipse((240, 772, 1220, 1140), rgba(grass_dark, 55), outline=(0, 0, 0, 0), width=0)

        for x in range(-30, 1980, 150):
            c.rect((x + 40, 382, x + 72, 552), wood, width=5, radius=12)
            c.line([(x + 52, 398), (x + 52, 532)], fill=wood_light, width=3)
        for y in [430, 508]:
            c.rect((-30, y, 1950, y + 26), wood, outline=wood_dark, width=5, radius=10)
            c.line([(0, y + 8), (1920, y + 8)], fill=wood_light, width=3)

        def soft_path(points: list[tuple[int, int]], width: int) -> None:
            c.line(points, fill=dirt_dark, width=width + 18)
            c.line(points, fill=dirt, width=width)
            c.line(points, fill=dirt_light, width=max(18, width // 3))

        soft_path([(960, 1080), (955, 930), (945, 790), (930, 650), (920, 530)], 150)
        soft_path([(920, 650), (745, 650), (560, 630), (395, 625), (320, 670)], 92)
        soft_path([(890, 820), (720, 845), (585, 890), (490, 930)], 94)
        soft_path([(1005, 665), (1160, 642), (1320, 628), (1470, 642)], 88)
        soft_path([(1010, 835), (1225, 860), (1435, 848), (1600, 825)], 100)

        # Activity pads are painted into the world so the scene reads like a farm, not loose icons.
        for x, y, w, h in [
            (320, 650, 410, 190),
            (500, 860, 500, 210),
            (920, 594, 500, 230),
            (1295, 654, 470, 220),
            (1585, 852, 480, 250),
        ]:
            c.ellipse((x - w / 2, y - h / 2, x + w / 2, y + h / 2), rgba((92, 155, 74, 255), 80), outline=(0, 0, 0, 0), width=0)
            c.ellipse((x - w / 2 + 28, y - h / 2 + 22, x + w / 2 - 28, y + h / 2 - 14), rgba((165, 226, 124, 255), 112), outline=(0, 0, 0, 0), width=0)

        # Chicken corner: coop fence, hay, and flowers frame the egg chore.
        c.rect((126, 314, 500, 354), wood, width=7, radius=18)
        c.rect((138, 492, 510, 528), wood, width=7, radius=16)
        for x in [156, 256, 366, 476]:
            c.rect((x - 14, 286, x + 14, 548), wood, width=6, radius=12)
        paste_asset(c, make_hay_bale(), 90, 496, 120)
        paste_asset(c, make_simple_prop("bush"), 450, 438, 140)

        # Cow stall nook: a barn-side frame behind the milking hotspot.
        c.rect((286, 640, 696, 890), cream, width=8, radius=36)
        c.poly([(262, 648), (490, 520), (720, 648)], COLORS["barn_red"], COLORS["outline"], 8)
        c.rect((300, 700, 682, 742), wood, width=7, radius=18)
        for x in [326, 490, 654]:
            c.rect((x - 16, 654, x + 16, 904), wood, width=6, radius=12)
        c.rect((370, 770, 610, 904), rgba((177, 112, 67, 255), 130), outline=wood_dark, width=6, radius=26)

        # Feeding pen and grooming stalls have their own clear spaces.
        c.rect((716, 472, 1124, 514), wood, width=7, radius=18)
        c.rect((706, 628, 1134, 664), wood, width=7, radius=16)
        for x in [740, 850, 970, 1085]:
            c.rect((x - 14, 438, x + 14, 682), wood, width=6, radius=12)
        paste_asset(c, make_feed_bag(), 704, 668, 94)
        paste_asset(c, make_hay_bale(), 1038, 664, 104)

        c.rect((1110, 514, 1490, 556), wood, width=7, radius=18)
        c.rect((1100, 708, 1500, 746), wood, width=7, radius=16)
        for x in [1130, 1238, 1350, 1460]:
            c.rect((x - 14, 488, x + 14, 770), wood, width=6, radius=12)
        c.rect((1176, 590, 1424, 720), rgba((255, 238, 190, 255), 155), outline=wood_dark, width=5, radius=24)
        paste_asset(c, make_brush(), 1418, 700, 92)

        # Garden patch: organized rows, edging, and a watering nook.
        c.rect((1364, 690, 1812, 988), (184, 116, 65, 255), width=8, radius=44)
        c.rect((1396, 722, 1780, 960), (214, 144, 82, 255), outline=(0, 0, 0, 0), width=0, radius=34)
        for y in [764, 826, 888, 948]:
            c.line([(1418, y), (1752, y - 12)], fill=(133, 82, 52, 255), width=14)
            c.line([(1435, y - 8), (1735, y - 18)], fill=(236, 177, 94, 255), width=4)
        for x, y in [(1470, 770), (1605, 820), (1715, 872), (1515, 926)]:
            c.line([(x, y + 28), (x, y - 20)], fill=COLORS["leaf"], width=7)
            c.ellipse((x - 26, y - 22, x + 22, y + 18), COLORS["leaf_light"], width=4)
        paste_asset(c, make_watering_can(), 1742, 706, 118)

        # A few curated props add warmth while preserving breathing room.
        paste_asset(c, make_simple_prop("tree"), 44, 156, 250)
        paste_asset(c, make_simple_prop("tree"), 1168, 190, 220)
        paste_asset(c, make_simple_prop("bush"), 88, 824, 160)
        paste_asset(c, make_simple_prop("bush"), 1736, 526, 150)
        paste_asset(c, make_hay_bale(), 760, 850, 116)
        paste_asset(c, make_hay_bale(), 1218, 850, 112)

        for x, y, color in [
            (720, 884, COLORS["pink"]),
            (790, 904, COLORS["yellow"]),
            (1098, 880, COLORS["blue"]),
            (1165, 910, COLORS["pink"]),
            (1518, 650, COLORS["yellow"]),
            (1660, 642, COLORS["pink"]),
        ]:
            c.line([(x, y + 26), (x, y + 2)], fill=COLORS["leaf"], width=4)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 13
                py = y + math.sin(math.radians(angle)) * 9
                c.ellipse((px - 8, py - 6, px + 8, py + 6), color, width=2)
            c.ellipse((x - 5, y - 5, x + 5, y + 5), COLORS["yellow"], width=1)
    elif kind == "feeding_yard_background":
        sky = (158, 223, 248, 255)
        grass = (114, 198, 96, 255)
        grass_light = (150, 218, 113, 255)
        wood = (205, 129, 73, 255)
        wood_light = (235, 162, 92, 255)
        wood_dark = (126, 78, 52, 255)
        barn_red = (212, 82, 68, 255)
        straw = (238, 198, 98, 255)
        dirt = (210, 146, 85, 255)

        c.rect((0, 0, 1920, 1080), sky, outline=(0, 0, 0, 0), width=0, radius=0)
        for x, y, size in [(260, 46, 220), (690, 36, 185), (1450, 54, 230)]:
            paste_asset(c, make_simple_prop("cloud"), x, y, size)
        c.rect((0, 520, 1920, 1080), grass, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-180, 456, 760, 738), rgba(grass_light, 105), outline=(0, 0, 0, 0), width=0)
        c.ellipse((1050, 452, 2120, 730), rgba(grass_light, 100), outline=(0, 0, 0, 0), width=0)

        # A warm feeding shed gives the scene the same built, storybook richness as the coop.
        c.rect((0, 214, 1920, 292), wood_dark, outline=(0, 0, 0, 0), width=0, radius=0)
        c.poly([(0, 214), (1920, 214), (1920, 270), (0, 304)], (164, 94, 55, 255), (0, 0, 0, 0), 0)
        c.rect((0, 292, 1920, 560), (255, 229, 174, 255), outline=(0, 0, 0, 0), width=0, radius=0)
        for x in range(-40, 1980, 160):
            plank = (250, 214, 150, 255) if int(x / 160) % 2 == 0 else (255, 238, 190, 255)
            c.rect((x, 292, x + 118, 560), plank, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(x + 120, 302), (x + 120, 558)], fill=(215, 166, 101, 255), width=4)
        for y in [350, 500]:
            c.rect((0, y, 1920, y + 34), wood_light, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(0, y + 34), (1920, y + 34)], fill=wood_dark, width=5)
        for x in [130, 430, 730, 1030, 1330, 1630]:
            c.rect((x, 232, x + 52, 596), wood, width=8, radius=16)
            c.line([(x + 15, 258), (x + 18, 570)], fill=wood_light, width=5)

        # Foreground dirt and straw create the feeding-yard focal area.
        c.poly([(260, 650), (1660, 650), (1870, 1080), (52, 1080)], dirt, (0, 0, 0, 0), 0)
        c.ellipse((180, 616, 1740, 862), rgba((232, 174, 96, 255), 94), outline=(0, 0, 0, 0), width=0)
        c.rect((0, 560, 1920, 606), wood_light, outline=(0, 0, 0, 0), width=0, radius=0)
        c.line([(0, 606), (1920, 606)], fill=wood_dark, width=6)
        for x in range(24, 1900, 96):
            c.line([(x, 790 + (x % 5) * 13), (x + 66, 760 + (x % 7) * 9)], fill=straw, width=5)
            c.line([(x + 18, 940 - (x % 4) * 12), (x + 110, 982 - (x % 6) * 8)], fill=(255, 222, 119, 255), width=5)

        paste_asset(c, make_hay_bale(), 82, 744, 174)
        paste_asset(c, make_hay_bale(), 1660, 746, 190)
        paste_asset(c, make_simple_prop("bush"), 30, 620, 190)
        paste_asset(c, make_simple_prop("bush"), 1718, 612, 190)
    elif kind == "chicken_coop_background":
        wall = (255, 228, 169, 255)
        wall_shadow = (241, 203, 136, 255)
        wood = (205, 129, 73, 255)
        wood_light = (232, 158, 88, 255)
        wood_dark = (126, 78, 52, 255)
        hay = (238, 198, 98, 255)
        hay_light = (255, 222, 119, 255)

        c.rect((0, 0, 1920, 1080), wall, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 0, 1920, 165), (181, 113, 67, 255), outline=(0, 0, 0, 0), width=0, radius=0)
        c.poly([(0, 165), (1920, 165), (1920, 220), (0, 195)], (143, 88, 57, 255), (0, 0, 0, 0), 0)

        # Broad planks and beams make the coop feel built, not flat.
        for x in range(-40, 1980, 160):
            tint = wall_shadow if int(x / 160) % 2 == 0 else (255, 236, 188, 255)
            c.rect((x, 165, x + 118, 720), tint, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(x + 120, 175), (x + 120, 720)], fill=(214, 166, 103, 255), width=4)
        for y in [245, 515]:
            c.rect((0, y, 1920, y + 36), (224, 154, 85, 255), outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(0, y + 36), (1920, y + 36)], fill=wood_dark, width=5)

        for x in [130, 540, 955, 1368, 1780]:
            c.rect((x, 145, x + 54, 730), wood, width=8, radius=16)
            c.line([(x + 15, 172), (x + 18, 700)], fill=wood_light, width=5)

        c.rect((0, 705, 1920, 1080), hay, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 705, 1920, 742), (198, 126, 69, 255), outline=(0, 0, 0, 0), width=0, radius=0)
        for x in range(20, 1900, 95):
            c.line([(x, 780 + (x % 3) * 18), (x + 68, 748 + (x % 5) * 10)], fill=(212, 155, 65, 255), width=5)
            c.line([(x + 20, 940 - (x % 4) * 12), (x + 110, 980 - (x % 6) * 9)], fill=hay_light, width=5)

        def nest_backboard(cx: int, cy: int, width: int, height: int) -> None:
            left = cx - width // 2
            top = cy - height // 2
            c.rect((left, top, left + width, top + height), (229, 158, 89, 255), width=10, radius=40)
            c.rect((left + 28, top + 28, left + width - 28, top + height - 28), (172, 101, 59, 255), width=7, radius=34)
            c.line([(left + 56, top + 58), (left + width - 54, top + 62)], fill=(246, 185, 104, 255), width=7)
            c.line([(left + 54, top + height - 54), (left + width - 58, top + height - 44)], fill=wood_dark, width=7)

        def shelf(cx: int, y: int, width: int) -> None:
            left = cx - width // 2
            c.rect((left, y, left + width, y + 42), wood, width=8, radius=14)
            c.rect((left - 18, y - 10, left + width + 18, y + 12), wood_light, width=7, radius=16)

        for cx in [552, 1340]:
            nest_backboard(cx, 352, 510, 260)
            shelf(cx, 430, 570)
        for cx, width in [(395, 470), (984, 510), (1566, 510)]:
            nest_backboard(cx, 660, width, 230)
            shelf(cx, 732, width + 62)

        paste_asset(c, make_hay_bale(), 80, 805, 190)
        paste_asset(c, make_hay_bale(), 1570, 780, 210)
    elif kind == "barn_background":
        c.rect((0, 0, 1920, 1080), (246, 226, 205, 255), outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 650, 1920, 1080), (202, 150, 99, 255), outline=(0, 0, 0, 0), width=0, radius=0)
        for x in range(0, 1920, 180):
            c.rect((x, 0, x + 90, 1080), rgba(COLORS["white"], 35), outline=(0, 0, 0, 0), width=0, radius=0)
        paste_asset(c, make_hay_bale(), 1260, 760, 220)
        paste_asset(c, make_simple_prop("fence_panel"), 120, 540, 300)
    elif kind == "brushing_barn_background":
        sky = (162, 225, 248, 255)
        grass = (116, 198, 98, 255)
        grass_light = (155, 222, 119, 255)
        wall = (255, 230, 178, 255)
        wall_soft = (255, 242, 206, 255)
        wood = (205, 129, 73, 255)
        wood_light = (236, 163, 93, 255)
        wood_dark = (126, 78, 52, 255)
        roof = (206, 96, 65, 255)
        roof_light = (243, 142, 82, 255)
        dirt = (211, 148, 86, 255)
        dirt_light = (235, 183, 112, 255)
        straw = (238, 198, 98, 255)

        c.rect((0, 0, 1920, 1080), sky, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 380, 1920, 1080), grass, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-260, 334, 740, 642), rgba(grass_light, 105), outline=(0, 0, 0, 0), width=0)
        c.ellipse((1040, 326, 2180, 650), rgba(grass_light, 100), outline=(0, 0, 0, 0), width=0)
        for x, y, size in [(210, 56, 210), (650, 48, 160), (1470, 74, 220)]:
            paste_asset(c, make_simple_prop("cloud"), x, y, size)

        # A close-up covered grooming aisle, with an open pasture peeking above the stalls.
        c.poly([(0, 230), (1920, 230), (1920, 324), (0, 352)], roof, (0, 0, 0, 0), 0)
        c.line([(0, 326), (1920, 300)], fill=wood_dark, width=8)
        c.rect((0, 320, 1920, 644), wall, outline=(0, 0, 0, 0), width=0, radius=0)
        for x in range(-40, 1980, 170):
            plank = wall_soft if int(x / 170) % 2 == 0 else (248, 214, 158, 255)
            c.rect((x, 320, x + 124, 644), plank, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(x + 126, 330), (x + 126, 640)], fill=(211, 157, 93, 255), width=4)
        for y in [398, 568]:
            c.rect((0, y, 1920, y + 36), wood_light, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(0, y + 36), (1920, y + 36)], fill=wood_dark, width=5)
        for x in [90, 388, 686, 984, 1282, 1580, 1848]:
            c.rect((x, 260, x + 54, 690), wood, width=8, radius=16)
            c.line([(x + 16, 292), (x + 18, 656)], fill=wood_light, width=5)

        # Foreground packed dirt and straw create a clear, calm brushing play area.
        c.rect((0, 644, 1920, 1080), dirt, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-140, 610, 2060, 910), rgba(dirt_light, 106), outline=(0, 0, 0, 0), width=0)
        c.rect((0, 626, 1920, 674), wood_light, outline=(0, 0, 0, 0), width=0, radius=0)
        c.line([(0, 674), (1920, 674)], fill=wood_dark, width=6)
        for x in range(18, 1900, 82):
            c.line([(x, 774 + (x % 4) * 14), (x + 68, 744 + (x % 6) * 10)], fill=straw, width=5)
            c.line([(x + 14, 940 - (x % 5) * 10), (x + 96, 984 - (x % 7) * 7)], fill=(255, 222, 119, 255), width=5)

        # Quiet props frame the scene without competing with the animals.
        paste_asset(c, make_hay_bale(), 72, 734, 180)
        paste_asset(c, make_hay_bale(), 1668, 748, 190)
        paste_asset(c, make_simple_prop("bush"), 6, 588, 170)
        paste_asset(c, make_simple_prop("bush"), 1740, 584, 170)
        paste_asset(c, make_brush(), 1452, 550, 118)
        for x, y, color in [(196, 648, COLORS["pink"]), (276, 674, COLORS["yellow"]), (1578, 650, COLORS["blue"]), (1660, 676, COLORS["pink"])]:
            c.line([(x, y + 28), (x, y + 4)], fill=COLORS["leaf"], width=4)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 13
                py = y + math.sin(math.radians(angle)) * 9
                c.ellipse((px - 8, py - 6, px + 8, py + 6), color, width=2)
            c.ellipse((x - 5, y - 5, x + 5, y + 5), COLORS["yellow"], width=1)
    elif kind == "milking_barn_background":
        wall = (247, 232, 210, 255)
        wall_soft = (255, 246, 229, 255)
        wall_shadow = (233, 214, 186, 255)
        wood = (184, 118, 69, 255)
        wood_light = (222, 156, 89, 255)
        wood_dark = (122, 75, 47, 255)
        straw = (202, 149, 95, 255)
        straw_light = (236, 198, 121, 255)
        sky = (177, 229, 248, 255)

        c.rect((0, 0, 1920, 1080), wall, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 0, 1920, 150), wood_dark, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 150, 1920, 680), wall_soft, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 680, 1920, 1080), straw, outline=(0, 0, 0, 0), width=0, radius=0)

        for x in range(0, 1920, 180):
            plank = wall_shadow if (x // 180) % 2 == 0 else (255, 240, 216, 255)
            c.rect((x, 150, x + 92, 680), plank, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(x + 92, 158), (x + 92, 680)], fill=(214, 181, 135, 255), width=4)
        for y in [226, 418, 610]:
            c.rect((0, y, 1920, y + 32), wood_light, outline=(0, 0, 0, 0), width=0, radius=0)
            c.line([(0, y + 32), (1920, y + 32)], fill=wood_dark, width=5)

        # Soft window light keeps the room airy and friendly.
        c.poly([(174, 206), (622, 206), (688, 372), (226, 372)], (248, 242, 219, 150), (0, 0, 0, 0), 0)
        c.rect((208, 168, 594, 362), sky, width=10, radius=28)
        c.line([(401, 170), (401, 360)], fill=wood, width=8)
        c.line([(214, 262), (588, 262)], fill=wood, width=8)
        c.line([(210, 170), (586, 360)], fill=(255, 255, 255, 70), width=5)

        c.poly([(1258, 206), (1710, 206), (1774, 372), (1314, 372)], (248, 240, 219, 140), (0, 0, 0, 0), 0)
        c.rect((1292, 168, 1678, 362), sky, width=10, radius=28)
        c.line([(1485, 170), (1485, 360)], fill=wood, width=8)
        c.line([(1298, 262), (1672, 262)], fill=wood, width=8)
        c.line([(1294, 170), (1670, 360)], fill=(255, 255, 255, 70), width=5)

        # Tiny lamp glow keeps the room cozy without dominating the scene.
        c.ellipse((886, 86, 1034, 206), (255, 248, 228, 60), outline=(0, 0, 0, 0), width=0)
        c.ellipse((908, 120, 1012, 214), (255, 244, 216, 34), outline=(0, 0, 0, 0), width=0)

        # Tiny, calm decorations keep the room farmy without adding odd posts or gates.
        paste_asset(c, make_hay_bale(), 1456, 762, 184)
        paste_asset(c, make_hay_bale(), 96, 790, 150)
        c.rect((150, 632, 356, 674), wood_light, width=8, radius=18)
        c.rect((1560, 632, 1766, 674), wood_light, width=8, radius=18)
        c.arc((864, 50, 1056, 182), 18, 162, fill=wood_light, width=10)
        c.ellipse((902, 92, 1018, 202), (255, 236, 165, 255), outline=wood_dark, width=7)
        c.line([(960, 202), (960, 236)], fill=wood_dark, width=8)
    elif kind in ["garden_background", "garden_care_background"]:
        sky = (160, 226, 249, 255)
        sky_light = (194, 239, 255, 255)
        grass = (116, 199, 96, 255)
        grass_light = (154, 222, 117, 255)
        grass_dark = (82, 164, 82, 255)
        wood = (206, 134, 78, 255)
        wood_light = (240, 178, 103, 255)
        wood_dark = (124, 76, 50, 255)
        dirt = (194, 126, 72, 255)
        dirt_light = (224, 157, 88, 255)
        dirt_dark = (126, 78, 50, 255)

        c.rect((0, 0, 1920, 1080), sky, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 0, 1920, 320), sky_light, outline=(0, 0, 0, 0), width=0, radius=0)
        for x, y, size in [(180, 60, 210), (620, 48, 160), (1420, 70, 225)]:
            paste_asset(c, make_simple_prop("cloud"), x, y, size)

        c.ellipse((-260, 318, 850, 610), rgba((166, 224, 128, 255), 135), outline=(0, 0, 0, 0), width=0)
        c.ellipse((690, 306, 2200, 628), rgba((150, 216, 115, 255), 128), outline=(0, 0, 0, 0), width=0)
        c.rect((0, 422, 1920, 1080), grass, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-180, 460, 760, 730), rgba(grass_light, 94), outline=(0, 0, 0, 0), width=0)
        c.ellipse((930, 472, 2140, 752), rgba(grass_light, 102), outline=(0, 0, 0, 0), width=0)

        for x in range(-40, 1980, 150):
            c.rect((x + 42, 356, x + 72, 526), wood, width=5, radius=12)
            c.line([(x + 54, 374), (x + 54, 506)], fill=wood_light, width=3)
        for y in [400, 478]:
            c.rect((-30, y, 1950, y + 26), wood, outline=wood_dark, width=5, radius=10)
            c.line([(0, y + 8), (1920, y + 8)], fill=wood_light, width=3)

        # A soft path and raised bed make the garden feel like a real place instead of a flat card.
        c.poly([(1220, 594), (1830, 650), (1920, 1080), (1130, 1080), (1038, 828)], (214, 151, 89, 255), (0, 0, 0, 0), 0)
        c.line([(1192, 620), (1800, 674)], fill=(236, 180, 107, 120), width=18)
        c.ellipse((254, 454, 1232, 1018), rgba(grass_dark, 70), outline=(0, 0, 0, 0), width=0)
        c.rect((228, 454, 1228, 982), dirt_dark, width=10, radius=58)
        c.rect((266, 490, 1190, 944), dirt, outline=(0, 0, 0, 0), width=0, radius=46)
        c.ellipse((286, 512, 1174, 916), rgba(dirt_light, 116), outline=(0, 0, 0, 0), width=0)
        for y in [562, 638, 720, 804, 884]:
            c.line([(330, y), (1136, y - 28)], fill=dirt_dark, width=18)
            c.line([(352, y - 8), (1114, y - 34)], fill=(246, 183, 96, 150), width=5)
        c.rect((222, 928, 1236, 986), wood, width=9, radius=22)
        c.line([(260, 940), (1198, 940)], fill=wood_light, width=5)
        for x in [350, 590, 830, 1070]:
            c.line([(x, 930), (x - 12, 984)], fill=wood_dark, width=6)

        # Tool nook and edge flowers add charm while keeping the tap area uncluttered.
        paste_asset(c, make_watering_can(), 1514, 692, 226)
        paste_asset(c, make_feed_bag(), 1358, 792, 118)
        c.rect((1344, 900, 1706, 942), wood, width=8, radius=18)
        c.rect((1392, 848, 1464, 928), (255, 225, 142, 255), width=7, radius=18)
        c.line([(1428, 844), (1428, 808)], fill=wood_dark, width=7)
        paste_asset(c, make_simple_prop("tree"), 60, 230, 240)
        paste_asset(c, make_simple_prop("bush"), 1700, 454, 170)
        paste_asset(c, make_simple_prop("bush"), 40, 828, 150)
        for x, y, color in [
            (310, 1000, COLORS["pink"]),
            (438, 1012, COLORS["yellow"]),
            (1110, 986, COLORS["blue"]),
            (1222, 1008, COLORS["pink"]),
            (1468, 962, COLORS["yellow"]),
            (1600, 982, COLORS["pink"]),
        ]:
            c.line([(x, y + 24), (x, y + 2)], fill=COLORS["leaf"], width=4)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 12
                py = y + math.sin(math.radians(angle)) * 8
                c.ellipse((px - 7, py - 5, px + 7, py + 5), color, width=2)
            c.ellipse((x - 4, y - 4, x + 4, y + 4), COLORS["yellow"], width=1)
    elif kind == "animal_pen_background":
        c.rect((0, 520, 1920, 600), (219, 151, 86, 255), width=0, outline=(0, 0, 0, 0), radius=0)
        for x in range(0, 1920, 260):
            paste_asset(c, make_simple_prop("fence_panel"), x, 410, 240)
        paste_asset(c, make_feed_bag(), 820, 170, 230)
        paste_asset(c, make_simple_prop("bush"), 90, 640, 220)
    elif kind in ["start_background", "start_scene_background"]:
        sky = (162, 226, 249, 255)
        sky_light = (202, 242, 255, 255)
        grass = (116, 199, 96, 255)
        grass_light = (154, 222, 117, 255)
        grass_dark = (82, 164, 82, 255)
        dirt = (216, 153, 91, 255)
        dirt_light = (239, 185, 112, 255)
        dirt_dark = (156, 95, 60, 255)
        wood = (206, 134, 78, 255)
        wood_light = (240, 178, 103, 255)
        wood_dark = (124, 76, 50, 255)

        c.rect((0, 0, 1920, 1080), sky, outline=(0, 0, 0, 0), width=0, radius=0)
        c.rect((0, 0, 1920, 330), sky_light, outline=(0, 0, 0, 0), width=0, radius=0)

        # A gentle morning sun and roomy sky keep the title area bright and welcoming.
        for angle in range(0, 360, 30):
            x = 164 + math.cos(math.radians(angle)) * 112
            y = 150 + math.sin(math.radians(angle)) * 112
            c.line([(164, 150), (x, y)], fill=(255, 224, 92, 230), width=10)
        c.ellipse((86, 72, 242, 228), (255, 224, 92, 255), width=8)
        draw_eye(c, 134, 138, "happy")
        draw_eye(c, 186, 138, "happy")
        draw_smile(c, 160, 162, True)
        for x, y, size in [(410, 70, 190), (1290, 76, 210), (1574, 184, 150)]:
            paste_asset(c, make_simple_prop("cloud"), x, y, size)

        c.ellipse((-280, 328, 940, 632), rgba((167, 225, 126, 255), 135), outline=(0, 0, 0, 0), width=0)
        c.ellipse((660, 318, 2200, 650), rgba((151, 218, 113, 255), 132), outline=(0, 0, 0, 0), width=0)
        c.rect((0, 520, 1920, 1080), grass, outline=(0, 0, 0, 0), width=0, radius=0)
        c.ellipse((-240, 552, 840, 812), rgba(grass_light, 96), outline=(0, 0, 0, 0), width=0)
        c.ellipse((930, 560, 2190, 832), rgba(grass_light, 98), outline=(0, 0, 0, 0), width=0)
        c.ellipse((360, 760, 1500, 1120), rgba(grass_dark, 58), outline=(0, 0, 0, 0), width=0)

        # Distant farm landmarks frame the title without competing with the play button.
        c.rect((1368, 414, 1708, 640), (255, 232, 179, 255), width=8, radius=28)
        c.poly([(1338, 420), (1538, 278), (1738, 420)], COLORS["barn_red"], COLORS["outline"], 9)
        c.rect((1410, 502, 1506, 640), (181, 104, 62, 255), width=7, radius=18)
        c.rect((1548, 486, 1652, 572), (174, 226, 243, 255), width=6, radius=18)
        c.line([(1599, 488), (1599, 570)], fill=wood_dark, width=4)
        c.line([(1552, 529), (1648, 529)], fill=wood_dark, width=4)
        paste_asset(c, make_simple_prop("tree"), 182, 372, 276)
        paste_asset(c, make_simple_prop("tree"), 1652, 418, 220)

        for x in range(-20, 1980, 160):
            c.rect((x + 42, 462, x + 72, 642), wood, width=5, radius=12)
            c.line([(x + 54, 482), (x + 54, 620)], fill=wood_light, width=3)
        for y in [506, 594]:
            c.rect((-30, y, 1950, y + 26), wood, outline=wood_dark, width=5, radius=10)
            c.line([(0, y + 8), (1920, y + 8)], fill=wood_light, width=3)

        # The path points toward the main Play button and makes the screen feel like an invitation.
        c.poly([(800, 666), (1120, 666), (1390, 1080), (520, 1080)], dirt, (0, 0, 0, 0), 0)
        c.line([(868, 718), (696, 1080)], fill=dirt_light, width=15)
        c.line([(1050, 718), (1208, 1080)], fill=dirt_dark, width=12)
        for x, y, rx, ry in [(806, 820, 40, 15), (1094, 892, 44, 16), (920, 994, 52, 18)]:
            c.ellipse((x - rx, y - ry, x + rx, y + ry), rgba(dirt_dark, 76), outline=(0, 0, 0, 0), width=0)

        paste_asset(c, make_hay_bale(), 92, 812, 172)
        paste_asset(c, make_hay_bale(), 1688, 794, 184)
        paste_asset(c, make_simple_prop("bush"), 18, 690, 180)
        paste_asset(c, make_simple_prop("bush"), 1752, 668, 178)
        for x, y, color in [
            (226, 940, COLORS["pink"]),
            (318, 968, COLORS["yellow"]),
            (1534, 920, COLORS["blue"]),
            (1628, 968, COLORS["pink"]),
            (724, 914, COLORS["yellow"]),
            (1212, 910, COLORS["pink"]),
        ]:
            c.line([(x, y + 30), (x, y + 4)], fill=COLORS["leaf"], width=4)
            for angle in range(0, 360, 72):
                px = x + math.cos(math.radians(angle)) * 13
                py = y + math.sin(math.radians(angle)) * 9
                c.ellipse((px - 8, py - 6, px + 8, py + 6), color, width=2)
            c.ellipse((x - 5, y - 5, x + 5, y + 5), COLORS["yellow"], width=1)
    return c.finish()


def generate_backgrounds() -> None:
    for kind in [
        "farmyard_background",
        "chicken_coop_background",
        "feeding_yard_background",
        "barn_background",
        "milking_barn_background",
        "garden_background",
        "garden_care_background",
        "animal_pen_background",
        "brushing_barn_background",
        "start_background",
        "start_scene_background",
    ]:
        save(make_background(kind), f"backgrounds/{kind}.png")


def write_audio_prompts() -> None:
    prompts = {
        "chicken_cluck_prompt.txt": "Short cheerful preschool cartoon chicken cluck, soft and friendly, no sharp peaks, under 1 second.",
        "completion_chime_prompt.txt": "Warm toddler-game completion chime with soft bells and tiny sparkle accents, positive and calm, 1-2 seconds.",
        "tap_pop_prompt.txt": "Gentle rounded tap pop for toddler mobile game feedback, soft attack, no harsh click, under 0.5 seconds.",
        "feed_munch_prompt.txt": "Cute soft munch or snack sound for friendly farm animals, playful and quiet, under 1 second.",
        "brush_swish_prompt.txt": "Gentle grooming brush swish, soft bristles, comforting toddler-game tone, under 1 second.",
    }
    out_dir = ART_ROOT / "audio_prompts"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, text in prompts.items():
        (out_dir / name).write_text(text + "\n", encoding="utf-8")


def generate_farmyard_layers() -> None:
    layers_dir = ART_ROOT / "backgrounds" / "farmyard_layers"
    layers_dir.mkdir(parents=True, exist_ok=True)

    W = 1920
    H = 1080
    sky = (156, 224, 249, 255)
    sky_light = (189, 239, 255, 255)
    grass = (112, 198, 98, 255)
    grass_light = (152, 223, 113, 255)
    grass_dark = (83, 166, 82, 255)
    dirt = (210, 148, 86, 255)
    dirt_light = (229, 171, 103, 255)
    dirt_dark = (160, 98, 61, 255)
    wood = (214, 139, 77, 255)
    wood_light = (244, 181, 102, 255)
    wood_dark = (128, 77, 49, 255)
    cream = (255, 232, 176, 255)
    straw = (239, 199, 99, 255)

    def layer_canvas() -> Canvas:
        return Canvas(W, H, transparent=True)

    # ----- sky.png -----
    c = layer_canvas()
    # Keep sky transparent below the horizon so it cannot tint farm art if reordered in the editor.
    c.rect((0, 0, W, 442), sky, outline=(0, 0, 0, 0), width=0, radius=0)
    c.rect((0, 0, W, 370), sky_light, outline=(0, 0, 0, 0), width=0, radius=0)
    for x, y, size in [(150, 70, 230), (565, 44, 170), (1190, 80, 185), (1570, 52, 220)]:
        paste_asset(c, make_simple_prop("cloud"), x, y, size)
    save(c.finish(), "backgrounds/farmyard_layers/sky.png")

    # ----- ground_base.png -----
    c = layer_canvas()
    # Opaque meadow backing prevents sky blue from showing through antialiased hill edges.
    c.rect((0, 370, W, H), (166, 222, 123, 255), outline=(0, 0, 0, 0), width=0, radius=0)
    # Distant hills are opaque so they keep their warm green color over the sky.
    c.ellipse((-220, 320, 950, 640), (171, 225, 126, 255), outline=(0, 0, 0, 0), width=0)
    c.ellipse((680, 326, 2150, 650), (155, 219, 116, 255), outline=(0, 0, 0, 0), width=0)
    c.rect((0, 442, W, H), grass, outline=(0, 0, 0, 0), width=0, radius=0)
    c.ellipse((-260, 512, 790, 766), (127, 207, 107, 255), outline=(0, 0, 0, 0), width=0)
    c.ellipse((980, 508, 2220, 790), (129, 207, 108, 255), outline=(0, 0, 0, 0), width=0)
    c.ellipse((240, 772, 1220, 1140), (105, 190, 97, 255), outline=(0, 0, 0, 0), width=0)

    # A continuous rear fence gives the farmyard a clear sense of place behind the activity areas.
    for x in range(-30, 1980, 150):
        c.rect((x + 40, 382, x + 72, 552), wood, width=5, radius=12)
        c.line([(x + 52, 398), (x + 52, 532)], fill=wood_light, width=3)
    for y in [430, 508]:
        c.rect((-30, y, 1950, y + 26), wood, outline=wood_dark, width=5, radius=10)
        c.line([(0, y + 8), (W, y + 8)], fill=wood_light, width=3)

    for x, y, w, h in [
        (320, 650, 410, 190),
        (500, 860, 500, 210),
        (920, 594, 500, 230),
        (1295, 654, 470, 220),
        (1585, 852, 480, 250),
    ]:
        c.ellipse((x - w / 2, y - h / 2, x + w / 2, y + h / 2), (106, 185, 90, 255), outline=(0, 0, 0, 0), width=0)
        c.ellipse((x - w / 2 + 28, y - h / 2 + 22, x + w / 2 - 28, y + h / 2 - 14), (135, 210, 109, 255), outline=(0, 0, 0, 0), width=0)

    save(c.finish(), "backgrounds/farmyard_layers/ground_base.png")

    # ----- paths.png -----
    c = layer_canvas()
    def soft_path(points: list[tuple[int, int]], width: int) -> None:
        c.line(points, fill=dirt_dark, width=width + 18)
        c.line(points, fill=dirt, width=width)
        c.line(points, fill=dirt_light, width=max(18, width // 3))

    soft_path([(960, H), (955, 930), (945, 790), (930, 650), (920, 530)], 150)
    soft_path([(920, 650), (745, 650), (560, 630), (395, 625), (320, 670)], 92)
    soft_path([(890, 820), (720, 845), (585, 890), (490, 930)], 94)
    soft_path([(1005, 665), (1160, 642), (1320, 628), (1470, 642)], 88)
    soft_path([(1010, 835), (1225, 860), (1435, 848), (1600, 825)], 100)
    save(c.finish(), "backgrounds/farmyard_layers/paths.png")

    # ----- decorative_props.png -----
    c = layer_canvas()
    paste_asset(c, make_simple_prop("tree"), 44, 156, 250)
    paste_asset(c, make_simple_prop("tree"), 1168, 190, 220)
    paste_asset(c, make_simple_prop("bush"), 88, 824, 160)
    paste_asset(c, make_simple_prop("bush"), 1736, 526, 150)
    paste_asset(c, make_hay_bale(), 760, 850, 116)
    paste_asset(c, make_hay_bale(), 1218, 850, 112)
    for x, y, color in [
        (720, 884, COLORS["pink"]),
        (790, 904, COLORS["yellow"]),
        (1098, 880, COLORS["blue"]),
        (1165, 910, COLORS["pink"]),
        (1518, 650, COLORS["yellow"]),
        (1660, 642, COLORS["pink"]),
    ]:
        c.line([(x, y + 26), (x, y + 2)], fill=COLORS["leaf"], width=4)
        for angle in range(0, 360, 72):
            px = x + math.cos(math.radians(angle)) * 13
            py = y + math.sin(math.radians(angle)) * 9
            c.ellipse((px - 8, py - 6, px + 8, py + 6), color, width=2)
        c.ellipse((x - 5, y - 5, x + 5, y + 5), COLORS["yellow"], width=1)
    save(c.finish(), "backgrounds/farmyard_layers/decorative_props.png")

    # ----- activity_back_fence.png -----
    # Shared back-fence layer for chicken, feeding, and brushing zones.
    c = layer_canvas()
    for x in [156, 256, 366, 476]:
        c.rect((x - 14, 286, x + 14, 548), wood, width=6, radius=12)
    c.rect((126, 314, 500, 354), wood, width=7, radius=18)
    c.rect((138, 492, 510, 528), wood, width=7, radius=16)
    paste_asset(c, make_hay_bale(), 90, 496, 120)
    paste_asset(c, make_simple_prop("bush"), 450, 438, 140)

    for x in [740, 850, 970, 1085]:
        c.rect((x - 14, 438, x + 14, 682), wood, width=6, radius=12)
    c.rect((716, 472, 1124, 514), wood, width=7, radius=18)
    c.rect((706, 628, 1134, 664), wood, width=7, radius=16)
    paste_asset(c, make_feed_bag(), 704, 668, 94)
    paste_asset(c, make_hay_bale(), 1038, 664, 104)

    for x in [1130, 1238, 1350, 1460]:
        c.rect((x - 14, 488, x + 14, 770), wood, width=6, radius=12)
    c.rect((1110, 514, 1490, 556), wood, width=7, radius=18)
    c.rect((1100, 708, 1500, 746), wood, width=7, radius=16)
    c.rect((1176, 590, 1424, 720), rgba((255, 238, 190, 255), 155), outline=wood_dark, width=5, radius=24)
    paste_asset(c, make_brush(), 1418, 700, 92)
    save(c.finish(), "backgrounds/farmyard_layers/activity_back_fence.png")

    # ----- cow_area.png -----
    c = layer_canvas()
    c.rect((286, 640, 696, 890), cream, width=8, radius=36)
    c.poly([(262, 648), (490, 520), (720, 648)], COLORS["barn_red"], COLORS["outline"], 8)
    c.rect((300, 700, 682, 742), wood, width=7, radius=18)
    for x in [326, 490, 654]:
        c.rect((x - 16, 654, x + 16, 904), wood, width=6, radius=12)
    c.rect((370, 770, 610, 904), rgba((177, 112, 67, 255), 130), outline=wood_dark, width=6, radius=26)
    save(c.finish(), "backgrounds/farmyard_layers/cow_area.png")

    # ----- garden_area.png -----
    c = layer_canvas()
    c.rect((1364, 690, 1812, 988), (184, 116, 65, 255), width=8, radius=44)
    c.rect((1396, 722, 1780, 960), (214, 144, 82, 255), outline=(0, 0, 0, 0), width=0, radius=34)
    for y in [764, 826, 888, 948]:
        c.line([(1418, y), (1752, y - 12)], fill=(133, 82, 52, 255), width=14)
        c.line([(1435, y - 8), (1735, y - 18)], fill=(236, 177, 94, 255), width=4)
    for x, y in [(1470, 770), (1605, 820), (1715, 872), (1515, 926)]:
        c.line([(x, y + 28), (x, y - 20)], fill=COLORS["leaf"], width=7)
        c.ellipse((x - 26, y - 22, x + 22, y + 18), COLORS["leaf_light"], width=4)
    paste_asset(c, make_watering_can(), 1742, 706, 118)
    save(c.finish(), "backgrounds/farmyard_layers/garden_area.png")


def main() -> None:
    ensure_dirs()
    generate_animals()
    generate_hub_feed_animals()
    generate_props()
    generate_garden()
    generate_effects()
    generate_ui()
    generate_backgrounds()
    generate_farmyard_layers()
    write_audio_prompts()


if __name__ == "__main__":
    main()
