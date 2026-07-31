#!/usr/bin/env python
"""
Generate the Goat Face store/marketing image assets:

    assets/app_icon_24bit.png   128x128  goat head icon (24-bit)
    assets/app_icon_64color.png 128x128  same icon, 64-color quantized
    assets/cover_image.png/.jpg 500x500  square promo
    assets/hero_image.png       1440x720 wide banner

The watch render is assets/screen_active.png if it is there (run
savescreenshot.ps1 with the simulator up), and a tools/goatart.py render of the
same face if it is not - so the art is right either way.

Run:  python tools/gen_assets.py
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from goatart import render, render_face, MEADOW  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")

CREAM = (0xF3, 0xE7, 0xCC)
SAGE = (0xC7, 0xD8, 0xB8)
PASTURE_TOP = (0x35, 0x6B, 0x8F)
PASTURE_BOTTOM = (0x2E, 0x5B, 0x2E)

# Whatever bold face this machine has; the store art is only generated locally.
FONT_CANDIDATES = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]


def load_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def fit_font(d, text, start, maxw):
    size = start
    while size > 10:
        f = load_font(size)
        if d.textlength(text, font=f) <= maxw:
            return f
        size -= 2
    return load_font(10)


def pasture(size):
    """Sky over grass, with a horizon."""
    w, h = size
    img = Image.new("RGB", size, PASTURE_TOP)
    d = ImageDraw.Draw(img)
    horizon = int(h * 0.62)
    for y in range(h):
        if y < horizon:
            t = y / float(max(horizon, 1))
            c = tuple(int(PASTURE_TOP[i] + (0x6E - PASTURE_TOP[i]) * t * 0.45) for i in range(3))
        else:
            t = (y - horizon) / float(max(h - horizon, 1))
            c = tuple(int(PASTURE_BOTTOM[i] * (1.0 - 0.35 * t)) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img


def watch_render(target, breed=0, t=17):
    """The simulator screenshot if we have one, otherwise a faithful render."""
    path = os.path.join(ASSETS, "screen_active.png")
    if os.path.exists(path):
        shot = Image.open(path).convert("RGBA").resize((target, target), Image.LANCZOS)
        mask = Image.new("L", (target, target), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, target - 2, target - 2], fill=255)
        shot.putalpha(mask)
        return shot
    print("  (no assets/screen_active.png - drawing the face instead)")
    return render_face(target, breed=breed, t=t)


def paste_watch_with_shadow(bg, watch, ox, oy):
    wsz = watch.size[0]
    pad = 40
    shadow = Image.new("RGBA", (wsz + pad * 2, wsz + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([pad, pad + 6, pad + wsz, pad + wsz + 6], fill=(10, 20, 10, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(12))
    bg.paste(shadow, (ox - pad, oy - pad), shadow)
    bg.paste(watch, (ox, oy), watch)


# ---------------------------------------------------------------- app icon

def gen_app_icon():
    img = render(128, bg=MEADOW, scale=0.86).convert("RGB")
    img.save(os.path.join(ASSETS, "app_icon_24bit.png"))
    img.convert("P", palette=Image.ADAPTIVE, colors=64).convert("RGB").save(
        os.path.join(ASSETS, "app_icon_64color.png"))
    print("app_icon_24bit.png / app_icon_64color.png  128x128")


# ---------------------------------------------------------------- cover

def gen_cover():
    S = 500
    bg = pasture((S, S)).convert("RGBA")

    watch = watch_render(int(S * 0.78))
    paste_watch_with_shadow(bg, watch, (S - watch.size[0]) // 2, int(S * 0.06))

    d = ImageDraw.Draw(bg)
    title = fit_font(d, "Goat Face", 62, S * 0.86)
    d.text((S / 2, S * 0.93), "Goat Face", font=title, fill=CREAM, anchor="mm")

    out = bg.convert("RGB")
    out.save(os.path.join(ASSETS, "cover_image.png"))
    out.save(os.path.join(ASSETS, "cover_image.jpg"), quality=90)
    print("cover_image.png / cover_image.jpg  500x500")


# ---------------------------------------------------------------- hero

def gen_hero():
    W, H = 1440, 720
    bg = pasture((W, H)).convert("RGBA")
    d = ImageDraw.Draw(bg)

    wsz = int(H * 0.80)
    wx = W - wsz - 70
    text_w = wx - 110 - 40

    title = fit_font(d, "Goat Face", 132, text_w)
    sub = fit_font(d, "a goat that blinks, chews and", 50, text_w)
    small = fit_font(d, "ten breeds - horns, floppy ears, beards", 38, text_w)

    d.text((110, 110), "Goat Face", font=title, fill=CREAM)
    d.text((110, 300), "a goat that blinks, chews and", font=sub, fill=(0xE6, 0xF0, 0xE0))
    d.text((110, 362), "sticks its tongue out at you", font=sub, fill=(0xE6, 0xF0, 0xE0))
    d.text((110, 480), "ten breeds - horns, floppy ears, beards", font=small, fill=SAGE)
    d.text((110, 536), "for Garmin round watches", font=small, fill=SAGE)

    # Two more of the herd, small, along the bottom under the text.
    for i, (bx, by, size, breed) in enumerate(((110, H - 130, 120, 2), (245, H - 118, 105, 8))):
        face = render_face(size, breed=breed, t=31 + i * 5, date_text=None,
                           fields=None, halter=False, time_text="")
        bg.alpha_composite(face, (bx, by))

    watch = watch_render(wsz)
    paste_watch_with_shadow(bg, watch, wx, (H - wsz) // 2)

    bg.convert("RGB").save(os.path.join(ASSETS, "hero_image.png"))
    print("hero_image.png  1440x720")


if __name__ == "__main__":
    os.makedirs(ASSETS, exist_ok=True)
    gen_app_icon()
    gen_cover()
    gen_hero()
    print("Done.")
