#!/usr/bin/env python
"""
Render the whole herd without opening the simulator.

    python tools/preview.py            -> assets/preview_breeds.png (all ten goats)
    python tools/preview.py anim       -> assets/preview_anim.png   (one goat, 12 seconds)

Uses tools/goatart.py, which mirrors the Monkey C artist. Handy for eyeballing a
layout change on every breed at once; the simulator is still the only place the
real thing runs.

Run:  python tools/preview.py
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from goatart import BREEDS, render_face, _font, DAYLIGHT  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")


def sheet(images, labels, cols, cell, pad=16, title_h=26):
    rows = (len(images) + cols - 1) // cols
    W = cols * (cell + pad) + pad
    H = rows * (cell + pad + title_h) + pad
    out = Image.new("RGB", (W, H), (18, 18, 20))
    d = ImageDraw.Draw(out)
    f = _font(15)
    for i, im in enumerate(images):
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + pad + title_h)
        out.paste(im, (x, y), im)
        d.text((x + cell // 2, y + cell + 12), labels[i], font=f,
               fill=(210, 210, 200), anchor="mm")
    return out


def breeds():
    size = 240
    imgs, labels = [], []
    for i, b in enumerate(BREEDS):
        imgs.append(render_face(size, breed=i, t=17 + i * 7))
        labels.append(b["name"])
    out = sheet(imgs, labels, 4, size)
    path = os.path.join(ASSETS, "preview_breeds.png")
    out.save(path)
    print(path, out.size)


def anim():
    size = 240
    imgs, labels = [], []
    # Runs across a yawn, so the sheet shows a gesture with a shape to it
    # rather than twelve unrelated frames.
    from goatart import gesture_at, GESTURE_NAMES, G_YAWN
    first = next(t for t in range(3600) if gesture_at(t) == G_YAWN)
    start = (first // 5) * 5 - 2
    for t in range(start, start + 12):
        imgs.append(render_face(size, breed=0, t=t))
        labels.append("%ds %s" % (t, GESTURE_NAMES[gesture_at(t)]))
    out = sheet(imgs, labels, 6, size)
    path = os.path.join(ASSETS, "preview_anim.png")
    out.save(path)
    print(path, out.size)


if __name__ == "__main__":
    os.makedirs(ASSETS, exist_ok=True)
    if len(sys.argv) > 1 and sys.argv[1] == "anim":
        anim()
    else:
        breeds()
        anim()
