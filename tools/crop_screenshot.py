#!/usr/bin/env python
"""
Crop the watch face out of a simulator window capture.

Finds the round display by looking for the face's own backdrop colour - which we
know exactly, because we drew it - and takes the union of the large patches of
it. Colour rather than geometry means it does not care about display scaling,
simulator zoom, or where the window sits.

Two things this has to get right, both learned the hard way:

  * the halter strap runs edge to edge, so the backdrop is *two* arcs, not one
    blob. Using the largest single patch gives a bounding box 529x309 instead of
    the square display.
  * a title-bar icon or taskbar button in a similar colour will stretch the
    bounding box across the whole screen, so small patches are dropped.

Run:  powershell -ExecutionPolicy Bypass -File tools\\grab_screenshot.ps1
      python tools/crop_screenshot.py [size]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "_simwin.png")
OUT = os.path.join(ROOT, "assets", "screen_active.png")

# Every backdrop GoatFaceView can draw. Ordered most-distinctive first: the last
# two sit close to the greys in the simulator's own watch artwork, so they are
# only tried if nothing else matched.
BACKDROPS = [0x1A5E9E, 0x452852, 0x632826, 0x265B26, 0x2E3338, 0x0E1626]
TOL = 20
MIN_PATCH = 700           # ignore icons and stray UI in the same colour
MIN_TOTAL = 15000         # smallest plausible display area in the capture


def find(a, color):
    """Union bounding box of the large patches of `color`, or None."""
    ref = np.array([(color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF])
    mask = np.abs(a - ref).max(axis=2) <= TOL
    if mask.sum() < MIN_TOTAL:
        return None
    lab, n = ndimage.label(mask)
    if n == 0:
        return None
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    keep = [i + 1 for i, s in enumerate(sizes) if s > MIN_PATCH]
    if not keep:
        return None
    ys, xs = np.where(np.isin(lab, keep))
    minx, maxx, miny, maxy = xs.min(), xs.max(), ys.min(), ys.max()
    bw, bh = maxx - minx + 1, maxy - miny + 1
    if not (0.85 <= bw / float(bh) <= 1.18):
        return None           # a round display is square in its bounding box
    return minx, maxx, miny, maxy


def main():
    size = int(sys.argv[1]) if len(sys.argv) > 1 else 454
    if not os.path.exists(SRC):
        print("No %s - run tools/grab_screenshot.ps1 first" % SRC)
        return 1

    img = Image.open(SRC).convert("RGB")
    a = np.asarray(img).astype(np.int16)

    hit = None
    for c in BACKDROPS:
        hit = find(a, c)
        if hit:
            print("backdrop 0x%06X" % c)
            break

    if not hit:
        print("Could not find the watch face. Is it actually on screen, and is "
              "the backdrop one of the built-in ones?")
        return 1

    minx, maxx, miny, maxy = hit
    side = max(maxx - minx + 1, maxy - miny + 1)
    cx, cy = (minx + maxx) // 2, (miny + maxy) // 2
    w, h = img.size
    left = max(0, min(cx - side // 2, w - side))
    top = max(0, min(cy - side // 2, h - side))
    print("display at (%d,%d) %dx%d" % (left, top, side, side))

    face = img.crop((left, top, left + side, top + side)).resize(
        (size, size), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    face.putalpha(mask)
    face.save(OUT)
    print("Saved %s (%dx%d)" % (OUT, size, size))
    return 0


if __name__ == "__main__":
    sys.exit(main())
