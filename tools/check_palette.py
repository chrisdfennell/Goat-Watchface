#!/usr/bin/env python
"""
Check the breed colours against the 64-colour MIP palette, and check that the
PIL mirror still agrees with the Monkey C source.

The older MIP watches (fenix 5/6, vivoactive 3/4, fr245/745/945, marq, ...)
declare a fixed palette: every channel snaps to 0x00/0x55/0xAA/0xFF. Two colours
landing on the same entry erase whatever shape they separated, so this asserts
that the colours carrying the goat's structure - coat, muzzle, eye, and the rim
where it can afford to - stay distinct after quantising, and that no coat
collides with the halter's leather.

Run:  python tools/check_palette.py
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MC = os.path.join(ROOT, "source", "Breeds.mc")

LEVELS = (0x00, 0x55, 0xAA, 0xFF)
KEY = ["coat", "muzzle", "eye"]          # must always be mutually distinct
RIM = "coatDark"                          # nice to have, may merge on dark goats
LEATHER = 0x46301E

COLOR_KEYS = ["coat", "coatDark", "coatLight", "muzzle", "muzzleDark",
              "earInner", "beardColor", "eye", "horn", "hornDark", "faceDark",
              "markColor", "faceInk"]


def snap(c):
    def n(v):
        return min(LEVELS, key=lambda L: abs(L - v))
    return (n((c >> 16) & 0xFF) << 16) | (n((c >> 8) & 0xFF) << 8) | n(c & 0xFF)


def parse_mc():
    s = io.open(MC, encoding="utf-8").read()
    defaults = {}
    for k in COLOR_KEYS:
        m = re.search(r"var %s as Number = 0x([0-9A-Fa-f]{6});" % k, s)
        if m:
            defaults[k] = int(m.group(1), 16)
    body = s[s.index("function get(index"):]
    starts = [m.end() for m in re.finditer(
        r"\n        (?:if \(i == \d+\) \{|\} else if \(i == \d+\) \{|\} else \{)", body)]
    starts.append(body.index("        return b;"))
    out = []
    for i in range(len(starts) - 1):
        seg = body[starts[i]:starts[i + 1]]
        cols = dict(defaults)
        for k in COLOR_KEYS:
            m = re.search(r"b\.%s = 0x([0-9A-Fa-f]{6})" % k, seg)
            if m:
                cols[k] = int(m.group(1), 16)
        name = re.search(r"// (.+?) -", seg)
        cols["name"] = name.group(1).strip() if name else "breed %d" % i
        out.append(cols)
    return out


def main():
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from goatart import BREEDS as MIRROR

    mc = parse_mc()
    problems = []

    if len(mc) != len(MIRROR):
        problems.append("breed count: Breeds.mc has %d, mirror has %d" % (len(mc), len(MIRROR)))

    # 1. the mirror must agree with the source
    for i in range(min(len(mc), len(MIRROR))):
        for k in COLOR_KEYS:
            if k in MIRROR[i] and k in mc[i] and MIRROR[i][k] != mc[i][k]:
                problems.append("%-17s %-11s source 0x%06X != mirror 0x%06X"
                                % (mc[i]["name"], k, mc[i][k], MIRROR[i][k]))

    # 2. the palette must keep the structure
    lea = snap(LEATHER)
    print("%-18s %-9s %-9s %-9s %-9s" % ("breed", "coat", "muzzle", "eye", "rim"))
    for b in mc:
        q = {k: snap(b[k]) for k in KEY + [RIM]}
        row = "  %-16s " % b["name"]
        row += " ".join("%06X " % q[k] for k in KEY + [RIM])
        notes = []
        if len({q[k] for k in KEY}) < len(KEY):
            notes.append("KEY COLLISION")
            problems.append("%s: coat/muzzle/eye collide after quantise" % b["name"])
        if q["coat"] == lea:
            notes.append("COAT == STRAP")
            problems.append("%s: coat quantises to the halter's leather" % b["name"])
        if q[RIM] == q["coat"]:
            notes.append("(rim merges - ok on a dark goat)")
        print(row + "  " + " ".join(notes))

    print()
    if problems:
        print("%d problem(s):" % len(problems))
        for p in problems:
            print("  - %s" % p)
        return 1
    print("OK: mirror matches source, and every breed survives the 64-colour palette.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
