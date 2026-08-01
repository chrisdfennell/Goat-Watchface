#!/usr/bin/env python
"""
The goat, drawn with PIL.

A deliberate line-for-line mirror of source/GoatArtist.mc + source/Breeds.mc:
same fraction constants, same palette, same draw order. That makes it (a) a
preview you can look at without the simulator - see tools/preview.py - and (b)
the source of the launcher icon and store art, so the artwork always matches the
goat that is actually on the watch.

If you change the Monkey C artist, change this too. Nothing here runs on device.
"""
import math

from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersampling factor

# Ear styles
EAR_UPRIGHT, EAR_DROOP, EAR_ELF, EAR_SIDE = 0, 1, 2, 3
# Horn styles
HORN_NONE, HORN_SPIKE, HORN_SWEPT, HORN_IBEX, HORN_SPIRAL = 0, 1, 2, 3, 4
# Beards
BEARD_NONE, BEARD_SHORT, BEARD_LONG = 0, 1, 2
# Face markings
MARK_NONE, MARK_BLAZE, MARK_STRIPES, MARK_MASK, MARK_DARK_FACE = 0, 1, 2, 3, 4

HINGE = 0.34

LEATHER = 0x46301E
CREAM = 0xF3E7CC
STITCH = 0xC9A96A
STEP_INK = 0xA6DDA6
MEADOW = 0x265B26
SLATE = 0x2E3338
DAYLIGHT = 0x1A5E9E

BREEDS = [
    dict(name="Nubian", coat=0x803F1D, coatDark=0x3C220E, coatLight=0x9A6636,
         muzzle=0xB08050, muzzleDark=0x4A2C13, earInner=0x8F5A32, beardColor=0x3C220E,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_DROOP, horns=HORN_NONE, beard=BEARD_SHORT, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Alpine", coat=0x9A722A, coatDark=0x4E2A1A, coatLight=0xC5A175,
         muzzle=0x2A2A26, muzzleDark=0x131110, earInner=0x6A4C2E, beardColor=0x1C1A18,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_UPRIGHT, horns=HORN_SWEPT, beard=BEARD_SHORT, marking=MARK_DARK_FACE,
         markColor=0xF2EEE3, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Boer", coat=0xA8451C, coatDark=0x66260E, coatLight=0xD4703C,
         muzzle=0xE8CDB4, muzzleDark=0x6B3A22, earInner=0xC96B44, beardColor=0x66260E,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_DROOP, horns=HORN_SWEPT, beard=BEARD_NONE, marking=MARK_BLAZE,
         markColor=0xF2EEE3, curly=False, faceInk=0x4A2A16, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Angora", coat=0xEFE6D0, coatDark=0xD5B47F, coatLight=0xFFFAEE,
         muzzle=0xE0B9A6, muzzleDark=0x8A6252, earInner=0xD8BFA8, beardColor=0xD8CBAF,
         eye=0x7FA3D5, horn=0xD3C09A, hornDark=0x9A886A,
         ear=EAR_UPRIGHT, horns=HORN_SPIRAL, beard=BEARD_LONG, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=True, faceInk=0x5A4A33, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Pygmy", coat=0x806D5D, coatDark=0x453C33, coatLight=0xA8967F,
         muzzle=0x8E8070, muzzleDark=0x2A241E, earInner=0x5E5346, beardColor=0x35302A,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_SIDE, horns=HORN_SPIKE, beard=BEARD_SHORT, marking=MARK_MASK,
         markColor=0x2A241E, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=0.92, eyeScale=1.12),
    dict(name="LaMancha", coat=0x462A27, coatDark=0x241813, coatLight=0x6E5040,
         muzzle=0x805C2A, muzzleDark=0x2A1C14, earInner=0x5A4034, beardColor=0x241813,
         eye=0xD9A441, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_ELF, horns=HORN_NONE, beard=BEARD_SHORT, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Toggenburg", coat=0x8A6B2A, coatDark=0x542A24, coatLight=0xB59468,
         muzzle=0xF0E8D4, muzzleDark=0x6A5238, earInner=0xB08C60, beardColor=0x543D24,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_UPRIGHT, horns=HORN_NONE, beard=BEARD_SHORT, marking=MARK_STRIPES,
         markColor=0xF2EEE3, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=True, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Saanen", coat=0xF2EFD4, coatDark=0xC6C0AE, coatLight=0xFFFFF6,
         muzzle=0xE9B2A4, muzzleDark=0x9A6A5E, earInner=0xE0C9BC, beardColor=0xDCD6C4,
         eye=0x7FB4D6, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_UPRIGHT, horns=HORN_NONE, beard=BEARD_SHORT, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0x55503F, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Wild Ibex", coat=0xB08B57, coatDark=0x804F2A, coatLight=0xD8B884,
         muzzle=0xD8C9AC, muzzleDark=0x5A4530, earInner=0x8A6A42, beardColor=0x2E2118,
         eye=0xE8B33C, horn=0x8F7C58, hornDark=0x5A4C34,
         ear=EAR_SIDE, horns=HORN_IBEX, beard=BEARD_LONG, marking=MARK_MASK,
         markColor=0x4A3520, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Black Bengal", coat=0x272727, coatDark=0x0D0D2B, coatLight=0x4E4E4E,
         muzzle=0x3C3C3C, muzzleDark=0x0A0A0A, earInner=0x333333, beardColor=0x141414,
         eye=0xE8A93C, horn=0x8C8272, hornDark=0x5A5246,
         ear=EAR_UPRIGHT, horns=HORN_SPIKE, beard=BEARD_SHORT, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B, wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Nigerian Dwarf", coat=0x803F1D, coatDark=0x2B1811, coatLight=0x7A5642,
         muzzle=0xF0E6D4, muzzleDark=0x5A4034, earInner=0x8A6A56, beardColor=0x241811,
         eye=0x7FB6DC, horn=0xC0AE8E, hornDark=0x877A62,
         ear=EAR_UPRIGHT, horns=HORN_SPIKE, beard=BEARD_SHORT, marking=MARK_BLAZE,
         markColor=0xF4EEE6, curly=False, faceInk=0x40281C, faceDark=0x241F1B,
         wattles=True, muzzleLen=0.88, eyeScale=1.22),
    dict(name="Oberhasli", coat=0xA0501F, coatDark=0x5A2A0E, coatLight=0xC97B3E,
         muzzle=0x2A2320, muzzleDark=0x100D0C, earInner=0x6E3A18, beardColor=0x181513,
         eye=0xE8B33C, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_UPRIGHT, horns=HORN_SWEPT, beard=BEARD_SHORT, marking=MARK_DARK_FACE,
         markColor=0xC97B3E, curly=False, faceInk=0xF5EFE0, faceDark=0x1E1A18,
         wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Valais Blacknose", coat=0xF4F0E6, coatDark=0xD5D5B4, coatLight=0xFFFFFA,
         muzzle=0x1E1C1B, muzzleDark=0x080807, earInner=0x2A2624, beardColor=0xDED8C8,
         eye=0xE8B33C, horn=0xC6B492, hornDark=0x8E7F63,
         ear=EAR_UPRIGHT, horns=HORN_SPIRAL, beard=BEARD_SHORT, marking=MARK_DARK_FACE,
         markColor=0x1C1A19, curly=True, faceInk=0x3A3532, faceDark=0x1C1A19,
         wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Markhor", coat=0x9C8E76, coatDark=0x5E543F, coatLight=0xC3B79C,
         muzzle=0xD5D5B2, muzzleDark=0x4A4234, earInner=0x7A6E58, beardColor=0x3A3226,
         eye=0xE8B33C, horn=0x8A7F66, hornDark=0x574E3C,
         ear=EAR_SIDE, horns=HORN_SPIRAL, beard=BEARD_LONG, marking=MARK_STRIPES,
         markColor=0xE4DCC8, curly=False, faceInk=0xF5EFE0, faceDark=0x241F1B,
         wattles=False, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Golden Guernsey", coat=0xD69B45, coatDark=0x94632B, coatLight=0xF0C075,
         muzzle=0xE9C89A, muzzleDark=0x7A5424, earInner=0xC08A44, beardColor=0x94631F,
         eye=0xC97F2A, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_SIDE, horns=HORN_NONE, beard=BEARD_SHORT, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0x4A3212, faceDark=0x241F1B,
         wattles=True, muzzleLen=1.0, eyeScale=1.0),
    dict(name="Kiko", coat=0xE6DCC4, coatDark=0xB0A57F, coatLight=0xF7F1E2,
         muzzle=0xD9BFA6, muzzleDark=0x7A6450, earInner=0xC9B294, beardColor=0xBFB396,
         eye=0xD8A441, horn=0xC9B58A, hornDark=0x8A7A5C,
         ear=EAR_SIDE, horns=HORN_IBEX, beard=BEARD_LONG, marking=MARK_NONE,
         markColor=0xF2EEE3, curly=False, faceInk=0x5C513A, faceDark=0x241F1B,
         wattles=False, muzzleLen=1.0, eyeScale=1.0),
]


# Set true to simulate the fixed 64-colour palette of the older MIP watches
# (fenix 5/6, vivoactive 3/4, fr245/745/945, marq, ...): every channel snaps to
# 0x00 / 0x55 / 0xAA / 0xFF. The device quantises each *fill colour*, not each
# pixel, which is why this hooks the colour helpers rather than the output image.
PALETTE64 = False
_LEVELS = (0x00, 0x55, 0xAA, 0xFF)


def _snap(v):
    return min(_LEVELS, key=lambda L: abs(L - v))


def quantize(rgb_tuple):
    if not PALETTE64:
        return rgb_tuple
    return tuple(_snap(v) for v in rgb_tuple)


def rgb(c):
    return quantize(((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF))


def tint(c, factor):
    r, g, b = (((c >> 16) & 0xFF), ((c >> 8) & 0xFF), (c & 0xFF))
    return quantize((min(255, int(r * factor)), min(255, int(g * factor)),
                     min(255, int(b * factor))))


def fizz(n):
    x = n * 48271 + 12345
    x = x ^ (x >> 13)
    x = x * 5
    x = x ^ (x >> 7)
    return x % 32749


G_NONE, G_EAR, G_TONGUE, G_YAWN, G_SHAKE, G_LOOK = range(6)
BUCKET = 5
GESTURE_NAMES = {G_NONE: "-", G_EAR: "ear", G_TONGUE: "tongue",
                 G_YAWN: "yawn", G_SHAKE: "shake", G_LOOK: "look"}


def gesture_at(t):
    roll = fizz(t // BUCKET + 991) % 100
    if roll < 56:
        return G_NONE
    if roll < 72:
        return G_EAR
    if roll < 83:
        return G_LOOK
    if roll < 91:
        return G_TONGUE
    if roll < 97:
        return G_SHAKE
    return G_YAWN


class Pose(object):
    """Mirror of source/Pose.mc."""

    def __init__(self, t=None, unit=454, motion=1.0):
        self.ox = self.oy = self.pupil = self.jaw = self.chew = self.breath = self.beard = 0
        self.tilt = 0.0
        self.blink = self.tongue = self.mouth = 0.0
        self.earL = self.earR = 0.0
        self.gesture = G_NONE
        if t is None or motion <= 0.0:
            return

        u = unit * motion
        phase = t % BUCKET
        g = gesture_at(t)
        self.gesture = g

        # idle layer
        self.tilt = ((fizz(t + 17) % 5) - 2) * 0.011 * u
        self.ox = int(((fizz(t) % 3) - 1) * (0.004 * u))
        self.oy = int(((fizz(t + 11) % 3) - 1) * (0.004 * u))
        self.breath = int(math.sin(t * 0.9) * 0.005 * u)
        self.beard = int(math.sin(t * 0.4) * 0.014 * u) + self.ox
        self.pupil = int(((fizz(t // 3 + 61) % 3) - 1) * 0.012 * u)
        if (fizz(t // 8) % 3) != 0:
            beat = t % 3
            if beat == 0:
                self.jaw, self.chew = 0, int(-0.010 * u)
            elif beat == 1:
                self.jaw, self.chew = int(0.024 * u), int(0.012 * u)
            else:
                self.jaw, self.chew = int(0.011 * u), 0

        if g == G_EAR:
            amp = {0: 0.34, 1: 0.15, 2: 0.05}.get(phase, 0.0)
            if amp:
                if (fizz(t // BUCKET + 13) % 2) == 0:
                    self.earL, self.earR = amp, amp * 0.25
                else:
                    self.earR, self.earL = amp, amp * 0.25
        elif g == G_LOOK:
            d = 1 if (fizz(t // BUCKET + 29) % 2) == 0 else -1
            if phase == 0:
                self.pupil = int(d * 0.020 * u)
            elif 1 <= phase <= 3:
                self.pupil = int(d * 0.030 * u)
                self.tilt += d * 0.014 * u
            else:
                self.pupil = int(d * 0.012 * u)
        elif g == G_TONGUE:
            self.tongue = {1: 0.55, 2: 1.0, 3: 0.45}.get(phase, 0.0)
            self.mouth = {1: 0.35, 2: 0.5, 3: 0.3}.get(phase, 0.0)
        elif g == G_SHAKE:
            if phase <= 3:
                swing = 1.0 if phase % 2 == 0 else -1.0
                decay = 1.0 if phase < 2 else 0.55
                self.tilt = swing * decay * 0.055 * u
                self.ox = int(swing * decay * 0.012 * u)
                self.earL = swing * decay * 0.30
                self.earR = -swing * decay * 0.30
        elif g == G_YAWN:
            spec = {1: (0.45, 0.55, 0.030, 0.0, 0.0),
                    2: (1.0, 1.0, 0.055, -0.020, 0.35),
                    3: (0.7, 1.0, 0.040, -0.012, 0.20),
                    4: (0.2, 0.4, 0.015, 0.0, 0.0)}.get(phase)
            if spec:
                self.mouth, self.blink, jw, tl, self.tongue = spec
                self.jaw = int(jw * u)
                self.tilt += tl * u
            self.chew = 0

        if g != G_YAWN:
            b = fizz(t + 7) % 13
            if b == 0:
                self.blink = 1.0
            elif b == 1:
                self.blink = 0.45


class Artist(object):
    """Mirror of source/GoatArtist.mc."""

    mz = 1.0

    def __init__(self, d, size, ox=0, oy=0):
        self.d = d
        self.S = size
        self.cx = ox + size // 2
        self.cy = oy + size // 2
        self.w = size
        self.fine = size >= 300
        self.pw = max(1, self.f(0.006))
        self.pwFat = max(2, self.f(0.011))
        self.strapCy = self.cy + self.f(0.060)
        self.strapH = self.f(0.175)

    # -- helpers
    def f(self, frac):
        return int(frac * self.S)

    def mx(self, p, xf, yf):
        return int(self.cx + p.ox + p.tilt * (HINGE - yf) + xf * self.S)

    def my(self, p, yf):
        return int(self.cy + p.oy + yf * self.S)

    def mp(self, p, xf, yf):
        return (self.mx(p, xf, yf), self.my(p, yf))

    def ell(self, x, y, a, b, fill):
        self.d.ellipse([x - a, y - b, x + a, y + b], fill=fill)

    # -- backdrop
    def backdrop(self, color, progress=-1.0):
        self.d.rectangle([self.cx - self.S, self.cy - self.S, self.cx + self.S, self.cy + self.S],
                         fill=rgb(color))
        if self.fine:
            r = self.S // 2
            ring = max(3, self.f(0.030))
            self.d.ellipse([self.cx - r + ring // 2, self.cy - r + ring // 2,
                            self.cx + r - ring // 2, self.cy + r - ring // 2],
                           outline=tint(color, 0.80), width=ring)
        if progress >= 0.0:
            self.goal_ring(color, progress)

    def goal_ring(self, back, progress):
        pen = max(3, self.f(0.022))
        rad = self.S // 2 - pen // 2 - 1
        box = [self.cx - rad, self.cy - rad, self.cx + rad, self.cy + rad]
        self.d.ellipse(box, outline=tint(back, 0.62), width=pen)
        if progress >= 0.01:
            if progress >= 1.0:
                self.d.ellipse(box, outline=rgb(STEP_INK), width=pen)
            else:
                # PIL measures degrees clockwise from three o'clock, so twelve
                # o'clock is -90. Monkey C counts the other way round from the
                # same place, which is why the two calls do not look alike.
                self.d.arc(box, -90, -90 + int(progress * 360),
                           fill=rgb(STEP_INK), width=pen)

    # -- goat
    def draw(self, b, p):
        self.mz = b["muzzleLen"]
        self.horn(b, p, -1)
        self.horn(b, p, 1)
        self.ear(b, p, -1, p.earL)
        self.ear(b, p, 1, p.earR)
        self.head(b, p)
        self.markings(b, p)
        if b["curly"] and self.fine:
            self.fleece(b, p)
        self.eyes(b, p)
        self.muzzle(b, p)
        self.beard(b, p)
        self.wattles(b, p)
        self.tongue(b, p)

    def horn(self, b, p, side):
        if b["horns"] == HORN_NONE:
            return
        bx, by = 0.100, -0.290
        c1x, c1y, ex, ey = 0.125, -0.370, 0.148, -0.428
        w0, w1, segs, ridged = 0.030, 0.008, 4, False
        if b["horns"] == HORN_SWEPT:
            c1x, c1y, ex, ey = 0.14, -0.43, 0.245, -0.385
            w0, w1, segs = 0.036, 0.010, 6
        elif b["horns"] == HORN_IBEX:
            c1x, c1y, ex, ey = 0.12, -0.45, 0.300, -0.350
            w0, w1, segs, ridged = 0.048, 0.014, 8, True
        elif b["horns"] == HORN_SPIRAL:
            c1x, c1y, ex, ey = 0.25, -0.39, 0.365, -0.265
            w0, w1, segs, ridged = 0.038, 0.011, 8, True

        x0, y0 = side * bx, by
        x1, y1 = side * c1x, c1y
        x2, y2 = side * ex, ey
        prev = None
        for i in range(segs + 1):
            t = i * 1.0 / segs
            mt = 1.0 - t
            qx = mt * mt * x0 + 2 * mt * t * x1 + t * t * x2
            qy = mt * mt * y0 + 2 * mt * t * y1 + t * t * y2
            tx = 2 * mt * (x1 - x0) + 2 * t * (x2 - x1)
            ty = 2 * mt * (y1 - y0) + 2 * t * (y2 - y1)
            ln = max(math.sqrt(tx * tx + ty * ty), 0.0001)
            half = w0 + (w1 - w0) * t
            nx, ny = -ty / ln * half, tx / ln * half
            lx, ly, rx, ry = qx + nx, qy + ny, qx - nx, qy - ny
            if prev is not None:
                self.d.polygon([self.mp(p, prev[0], prev[1]), self.mp(p, lx, ly),
                                self.mp(p, rx, ry), self.mp(p, prev[2], prev[3])], fill=rgb(b["horn"]))
                if ridged and self.fine:
                    self.d.line([self.mp(p, lx, ly), self.mp(p, rx, ry)],
                                fill=rgb(b["hornDark"]), width=self.pw)
            prev = (lx, ly, rx, ry)
        self.ell(self.mx(p, x2, y2), self.my(p, y2), self.f(w1) + 1, self.f(w1) + 1, rgb(b["hornDark"]))

    def ear(self, b, p, side, twist):
        theta, ln, t0, t1, px, py = -0.50, 0.185, 0.072, 0.030, 0.165, -0.215
        if b["ear"] == EAR_DROOP:
            self.droop_ear(b, p, side, twist)
            return
        elif b["ear"] == EAR_ELF:
            theta, ln, t0, t1, px, py = -0.35, 0.055, 0.038, 0.028, 0.205, -0.190
        elif b["ear"] == EAR_SIDE:
            theta, ln, t0, t1, px, py = -0.22, 0.180, 0.058, 0.022, 0.190, -0.185

        a = theta + twist
        ca, sa = math.cos(a), math.sin(a)
        bxf, byf = side * px, py
        axX, axY = side * ca, sa
        self._nx, self._ny = -sa, side * ca

        self._slab(p, bxf, byf, bxf + axX * ln, byf + axY * ln, t0, t1, rgb(b["coatDark"]))
        self._slab(p, bxf, byf, bxf + axX * ln * 0.86, byf + axY * ln * 0.86,
                   t0 * 0.66, t1 * 0.60, rgb(b["coat"]))
        self._slab(p, bxf, byf, bxf + axX * ln * 0.72, byf + axY * ln * 0.72,
                   t0 * 0.34, t1 * 0.30, rgb(b["earInner"]))

    def droop_ear(self, b, p, side, twist):
        a1 = 1.12 + twist
        a2 = 1.48 + twist * 0.55
        bxf, byf = side * 0.215, -0.235
        m1x = bxf + side * math.cos(a1) * 0.215
        m1y = byf + math.sin(a1) * 0.215
        tipx = m1x + side * math.cos(a2) * 0.235
        tipy = m1y + math.sin(a2) * 0.235
        for scale, color, reach in ((1.0, b["coatDark"], 1.0), (0.66, b["coat"], 0.90),
                                    (0.34, b["earInner"], 0.76)):
            self._nx, self._ny = -math.sin(a1), side * math.cos(a1)
            self._slab(p, bxf, byf, m1x, m1y, 0.062 * scale, 0.056 * scale, rgb(color))
            self._nx, self._ny = -math.sin(a2), side * math.cos(a2)
            ex = m1x + (tipx - m1x) * reach
            ey = m1y + (tipy - m1y) * reach
            self._slab(p, m1x, m1y, ex, ey, 0.056 * scale, 0.044 * scale, rgb(color))

    def _slab(self, p, x0, y0, x1, y1, h0, h1, fill):
        nx, ny = self._nx, self._ny
        self.d.polygon([self.mp(p, x0 + nx * h0, y0 + ny * h0),
                        self.mp(p, x1 + nx * h1, y1 + ny * h1),
                        self.mp(p, x1 - nx * h1, y1 - ny * h1),
                        self.mp(p, x0 - nx * h0, y0 - ny * h0)], fill=fill)
        r = self.f(h1)
        self.ell(self.mx(p, x1, y1), self.my(p, y1), r, r, fill)

    def _head_shapes(self, p, d, fill):
        self.ell(self.mx(p, 0.0, -0.185), self.my(p, -0.185), self.f(0.245) + d, self.f(0.190) + d, fill)
        self.ell(self.mx(p, 0.0, -0.010), self.my(p, -0.010), self.f(0.205) + d, self.f(0.170) + d, fill)
        w_ = 0.320 * self.mz
        c_ = 0.315 * self.mz
        self.d.polygon([(self.mx(p, -0.190, -0.050) - d, self.my(p, -0.050)),
                        (self.mx(p, 0.190, -0.050) + d, self.my(p, -0.050)),
                        (self.mx(p, 0.125, w_) + d, self.my(p, w_) + d),
                        (self.mx(p, -0.125, w_) - d, self.my(p, w_) + d)], fill=fill)
        self.ell(self.mx(p, 0.0, c_), self.my(p, c_), self.f(0.125) + d, self.f(0.090) + d, fill)

    def head(self, b, p):
        self._head_shapes(p, self.pwFat, rgb(b["coatDark"]))
        self._head_shapes(p, 0, rgb(b["coat"]))
        for s in (-1, 1):
            self.ell(self.mx(p, s * 0.142, 0.030), self.my(p, 0.030),
                     self.f(0.050), self.f(0.072), rgb(b["coatLight"]))
        sh = 0.352 * self.mz
        self.ell(self.mx(p, 0.0, sh), self.my(p, sh), self.f(0.112), self.f(0.042),
                 tint(b["coat"], 0.84))

    def markings(self, b, p):
        m = b["marking"]
        if m == MARK_BLAZE:
            self.d.polygon([self.mp(p, -0.075, -0.360), self.mp(p, 0.075, -0.360),
                            self.mp(p, 0.104, 0.320 * self.mz), self.mp(p, -0.104, 0.320 * self.mz)],
                           fill=rgb(b["markColor"]))
        elif m == MARK_STRIPES:
            for s in (-1, 1):
                self.d.polygon([self.mp(p, s * 0.186, -0.320), self.mp(p, s * 0.136, -0.320),
                                self.mp(p, s * 0.100, 0.270 * self.mz), self.mp(p, s * 0.140, 0.270 * self.mz)],
                               fill=rgb(b["markColor"]))
        elif m == MARK_MASK:
            for s in (-1, 1):
                self.ell(self.mx(p, s * 0.150, -0.150), self.my(p, -0.150),
                         self.f(0.112), self.f(0.082), rgb(b["markColor"]))
            self.d.polygon([self.mp(p, -0.095, -0.360), self.mp(p, 0.095, -0.360),
                            self.mp(p, 0.058, -0.120), self.mp(p, -0.058, -0.120)],
                           fill=rgb(b["markColor"]))
        elif m == MARK_DARK_FACE:
            self.ell(self.mx(p, 0.0, -0.150), self.my(p, -0.150),
                     self.f(0.196), self.f(0.222), rgb(b["faceDark"]))
            self.d.polygon([self.mp(p, -0.180, -0.010), self.mp(p, 0.180, -0.010),
                            self.mp(p, 0.120, 0.310 * self.mz),
                            self.mp(p, -0.120, 0.310 * self.mz)], fill=rgb(b["faceDark"]))
            for s in (-1, 1):
                self.d.polygon([self.mp(p, s * 0.188, -0.300), self.mp(p, s * 0.124, -0.300),
                                self.mp(p, s * 0.096, 0.150), self.mp(p, s * 0.144, 0.150)],
                               fill=rgb(b["markColor"]))

    def fleece(self, b, p):
        r = max(3, self.f(0.030))
        for i in range(16):
            ang = 3.1416 + i * 0.2094
            rad = 0.205 + (fizz(i) % 5) * 0.008
            xf = math.cos(ang) * rad
            yf = -0.165 + math.sin(ang) * rad * 0.90
            self.ell(self.mx(p, xf, yf), self.my(p, yf), r, r,
                     rgb(b["coatLight"] if i % 2 == 0 else b["coatDark"]))
        for j in range(-2, 3):
            self.ell(self.mx(p, j * 0.068, -0.300), self.my(p, -0.300),
                     self.f(0.046), self.f(0.046), rgb(b["coatLight"]))

    def eyes(self, b, p):
        lid = b["coat"]
        if b["marking"] == MARK_MASK:
            lid = b["markColor"]
        elif b["marking"] == MARK_DARK_FACE:
            lid = b["faceDark"]
        for s in (-1, 1):
            self._eye(b, p, self.mx(p, s * 0.150, -0.150), self.my(p, -0.150), lid)

    def _eye(self, b, p, ex, ey, lid):
        a = int(0.070 * b['eyeScale'] * self.S)
        bb = int(0.046 * b['eyeScale'] * self.S)
        self.ell(ex, ey, a + self.pw, bb + self.pw, tint(b["coatDark"], 0.75))
        self.ell(ex, ey, a, bb, rgb(b["eye"]))
        pw_ = int(0.104 * b['eyeScale'] * self.S)
        ph = max(3, int(0.026 * b['eyeScale'] * self.S))
        self.d.rounded_rectangle([ex - pw_ // 2 + p.pupil, ey - ph // 2,
                                  ex - pw_ // 2 + p.pupil + pw_, ey - ph // 2 + ph],
                                 radius=ph // 2, fill=rgb(0x101010))
        hl = max(2, self.f(0.011))
        self.ell(ex - self.f(0.030) + p.pupil, ey - self.f(0.018), hl, hl, (255, 255, 255))
        if p.blink > 0.0:
            drop = int(((bb + self.pw) * 2 + 2) * p.blink)
            top = ey - bb - self.pw - 1
            self.d.rectangle([ex - a - self.pw, top, ex + a + self.pw, top + drop], fill=rgb(lid))
            self.d.line([(ex - a, top + drop), (ex + a, top + drop)],
                        fill=tint(b["coatDark"], 0.8), width=self.pw)

    def muzzle(self, b, p):
        pad = 0.305 * self.mz
        nose = 0.278 * self.mz
        lip = 0.318 * self.mz
        self.ell(self.mx(p, 0.0, pad), self.my(p, pad), self.f(0.142), self.f(0.098), rgb(b["muzzle"]))
        for s in (-1, 1):
            self.ell(self.mx(p, s * 0.055, nose), self.my(p, nose) - p.breath,
                     self.f(0.028), self.f(0.020), rgb(b["muzzleDark"]))
        self.d.line([self.mp(p, 0.0, 0.298 * self.mz),
                     (self.mx(p, 0.0, 0.332 * self.mz), self.my(p, 0.332 * self.mz) + p.jaw)],
                    fill=rgb(b["muzzleDark"]), width=self.pw)
        mx0 = self.mx(p, 0.0, lip) + p.chew
        my0 = self.my(p, lip) + p.jaw
        r = self.f(0.070)
        self.d.arc([mx0 - r, my0 - r, mx0 + r, my0 + r], 35, 145,
                   fill=rgb(b["muzzleDark"]), width=self.pw)

        if p.mouth > 0.0:
            openH = max(2, int(0.072 * p.mouth * self.S))
            openW = self.f(0.062) + int(0.030 * p.mouth * self.S)
            gape = 0.340 * self.mz
            ox_ = self.mx(p, 0.0, gape) + p.chew
            oy_ = self.my(p, gape) + p.jaw
            self.ell(ox_, oy_, openW, openH, tint(b["muzzleDark"], 0.55))
            self.d.arc([ox_ - openW, oy_ - openH, ox_ + openW, oy_ + openH], 20, 160,
                       fill=tint(b["muzzleDark"], 1.6), width=self.pw)

    def beard(self, b, p):
        if b["beard"] == BEARD_NONE:
            return
        lenf = 0.135 if b["beard"] == BEARD_LONG else 0.085
        topf = 0.378 * self.mz
        botf = topf + lenf
        sway = p.beard
        self.d.polygon([self.mp(p, -0.060, topf), self.mp(p, 0.060, topf),
                        (self.mx(p, 0.032, botf) + sway, self.my(p, botf)),
                        (self.mx(p, -0.032, botf) + sway, self.my(p, botf))], fill=rgb(b["beardColor"]))
        r = self.f(0.032)
        self.ell(self.mx(p, 0.0, botf) + sway, self.my(p, botf), r, r, rgb(b["beardColor"]))
        if self.fine:
            c = tint(b["beardColor"], 1.35)
            self.d.line([self.mp(p, -0.020, topf + 0.015),
                         (self.mx(p, -0.010, botf - 0.010) + sway, self.my(p, botf - 0.010))],
                        fill=c, width=self.pw)
            self.d.line([self.mp(p, 0.022, topf + 0.015),
                         (self.mx(p, 0.014, botf - 0.010) + sway, self.my(p, botf - 0.010))],
                        fill=c, width=self.pw)

    def wattles(self, b, p):
        if not b["wattles"]:
            return
        topf = 0.360 * self.mz
        botf = topf + 0.060
        sway = p.beard // 2
        r = max(2, self.f(0.020))
        for s in (-1, 1):
            self.d.polygon([self.mp(p, s * 0.078, topf), self.mp(p, s * 0.106, topf),
                            (self.mx(p, s * 0.100, botf) + sway, self.my(p, botf)),
                            (self.mx(p, s * 0.084, botf) + sway, self.my(p, botf))],
                           fill=rgb(b["coatDark"]))
            self.ell(self.mx(p, s * 0.092, botf) + sway, self.my(p, botf), r, r, rgb(b["coatDark"]))
            self.ell(self.mx(p, s * 0.092, botf) + sway, self.my(p, botf),
                     r - self.pw, r - self.pw, rgb(b["coat"]))

    def tongue(self, b, p):
        if p.tongue <= 0.0:
            return
        topf = 0.354 * self.mz
        xc = self.mx(p, 0.0, topf) + p.chew
        yt = self.my(p, topf) + p.jaw
        ln = int(0.070 * p.tongue * self.S)
        half = self.f(0.030)
        self.ell(xc, yt, self.f(0.048), self.f(0.020), rgb(b["muzzleDark"]))
        self.d.rounded_rectangle([xc - half, yt - self.f(0.008), xc + half, yt + ln + self.f(0.016)],
                                 radius=half, fill=rgb(0xE87A93))
        self.d.line([(xc, yt + self.f(0.010)), (xc, yt + ln - self.f(0.006))],
                    fill=rgb(0xC85B78), width=self.pw)

    def halter(self):
        top = self.strapCy - self.strapH // 2
        edge = max(2, self.f(0.009))
        x0, x1 = self.cx - self.S, self.cx + self.S
        self.d.rectangle([x0, top, x1, top + self.strapH], fill=rgb(LEATHER))
        self.d.rectangle([x0, top, x1, top + edge], fill=tint(LEATHER, 1.55))
        self.d.rectangle([x0, top + self.strapH - edge, x1, top + self.strapH], fill=tint(LEATHER, 0.55))
        if self.fine:
            y1 = top + edge + self.f(0.018)
            y2 = top + self.strapH - edge - self.f(0.018)
            step, dash = self.f(0.055), self.f(0.022)
            x = x0 + step // 2
            while x < x1:
                self.d.line([(x, y1), (x + dash, y1)], fill=rgb(STITCH), width=self.pw)
                self.d.line([(x, y2), (x + dash, y2)], fill=rgb(STITCH), width=self.pw)
                x += step


def _font(size):
    import os
    for path in (r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\arialbd.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def render_face(size, breed=0, t=None, backdrop=DAYLIGHT, halter=True,
                time_text="10:08", date_text="FRI JUL 31",
                fields=(("STEPS", "8,241", STEP_INK), ("BATT", "87%", STEP_INK)),
                motion=1.0, round_mask=True, progress=-1.0, meridiem=None,
                weary=0.0):
    """A full watch face, drawn the way GoatFaceView.onUpdate would draw it."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    art = Artist(d, big)
    b = BREEDS[breed % len(BREEDS)]
    p = Pose(t, unit=big, motion=motion)
    if weary > 0.0 and p.blink < weary:
        p.blink = weary

    art.backdrop(backdrop, progress)
    art.draw(b, p)

    if date_text:
        f = _font(int(big * 0.055))
        dy = art.cy - int(big * 0.265)
        ink = b["faceInk"]
        lum = (((ink >> 16) & 0xFF) * 2 + ((ink >> 8) & 0xFF) * 3 + (ink & 0xFF)) // 6
        halo = 0x121212 if lum > 128 else 0xF2F2F2
        o = max(1, big // 454)
        for ox_, oy_ in ((-o, 0), (o, 0), (0, -o), (0, o)):
            d.text((art.cx + ox_, dy + oy_), date_text, font=f, fill=rgb(halo), anchor="mm")
        d.text((art.cx, dy), date_text, font=f, fill=rgb(ink), anchor="mm")
    if halter:
        art.halter()
    tf = _font(int(art.strapH * 0.78))
    d.text((art.cx, art.strapCy), time_text, font=tf, fill=rgb(CREAM), anchor="mm")
    if meridiem:
        d.text((art.cx + d.textlength(time_text, font=tf) / 2 + int(big * 0.020),
                art.strapCy), meridiem, font=_font(int(big * 0.055)),
               fill=tint(CREAM, 0.80), anchor="lm")

    if fields:
        f = _font(int(big * 0.055))
        lh = int(big * 0.070)
        y = art.cy + int(big * 0.322)
        dx = int(big * 0.265)
        for i, (label, value, col) in enumerate(fields):
            fx = art.cx + (dx if i else -dx)
            d.text((fx, y - int(lh * 0.44)), label, font=f, fill=tint(col, 0.62), anchor="mm")
            d.text((fx, y + int(lh * 0.42)), value, font=f, fill=rgb(col), anchor="mm")

    out = img.resize((size, size), Image.LANCZOS)
    if round_mask:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
        out.putalpha(mask)
    return out


def render(size, bg=MEADOW, scale=0.86):
    """Just the goat head on a filled circle - the launcher icon."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, big - 1, big - 1], fill=rgb(bg) + (255,))
    head = int(big * scale)
    art = Artist(d, head, ox=(big - head) // 2, oy=(big - head) // 2 + int(big * 0.03))
    art.draw(BREEDS[0], Pose())
    return img.resize((size, size), Image.LANCZOS)
