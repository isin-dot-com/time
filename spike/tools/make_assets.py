#!/usr/bin/env python3
"""Generates the spike's binary assets (committed to the repo, CI does not rerun this).

Outputs (relative to spike/):
  Resources/Fonts/SpikeSegment.ttf                     - 7-segment digits font (PostScript name SpikeSegment-Regular)
  Resources/Sounds/quiet.wav                           - 0.4 s, very quiet 660 Hz beep (16-bit PCM mono)
  Resources/Sounds/silent.wav                          - 1.0 s of digital silence (16-bit PCM mono)
  App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png - 1024x1024 opaque RGB PNG

Requirements: python3, fonttools, pillow  (pip install fonttools pillow)
Run from anywhere:  python spike/tools/make_assets.py
"""
import math
import os
import struct
import wave

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # spike/

# ---------------------------------------------------------------- font
UPM = 1000
ASCENT, DESCENT = 800, -200
DIGIT_ADV = 620
X0, X1, H, T = 60, 560, 700, 90  # digit box and segment thickness

# Disjoint rectangles: verticals at x 60-150 / 470-560, horizontals at x 165-455.
SEG = {
    "a": (165, H - T, 455, H),          # top
    "g": (165, 305, 455, 395),          # middle
    "d": (165, 0, 455, T),              # bottom
    "f": (X0, 365, X0 + T, H),          # upper left
    "b": (X1 - T, 365, X1, H),          # upper right
    "e": (X0, 0, X0 + T, 335),          # lower left
    "c": (X1 - T, 0, X1, 335),          # lower right
}
DIGITS = {
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
    "5": "afgcd", "6": "afgecd", "7": "abc", "8": "abcdefg", "9": "abcdfg",
}
NAMES = {"0": "zero", "1": "one", "2": "two", "3": "three", "4": "four",
         "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine"}


def rect(pen, x0, y0, x1, y1):
    # Clockwise in a y-up system = TrueType outer contour direction.
    pen.moveTo((x0, y0))
    pen.lineTo((x0, y1))
    pen.lineTo((x1, y1))
    pen.lineTo((x1, y0))
    pen.closePath()


def glyph(rects):
    pen = TTGlyphPen(None)
    for r in rects:
        rect(pen, *r)
    return pen.glyph()


def build_font(path):
    glyphs, advances, cmap = {}, {}, {}
    glyphs[".notdef"] = glyph([(50, 0, 450, 700)]); advances[".notdef"] = 500
    glyphs["space"] = glyph([]); advances["space"] = 300
    for ch, segs in DIGITS.items():
        name = NAMES[ch]
        glyphs[name] = glyph([SEG[s] for s in segs])
        advances[name] = DIGIT_ADV
        cmap[ord(ch)] = name
    glyphs["colon"] = glyph([(80, 150, 170, 240), (80, 460, 170, 550)]); advances["colon"] = 250
    glyphs["period"] = glyph([(80, 0, 170, 90)]); advances["period"] = 250
    glyphs["hyphen"] = glyph([(80, 305, 420, 395)]); advances["hyphen"] = 500
    cmap.update({0x20: "space", 0xA0: "space", 0x202F: "space", 0x2009: "space",
                 ord(":"): "colon", ord("."): "period", ord("-"): "hyphen", 0x2212: "hyphen"})

    order = [".notdef", "space"] + [NAMES[c] for c in "0123456789"] + ["colon", "period", "hyphen"]
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    glyf = fb.font["glyf"]
    metrics = {}
    for gn in order:
        g = glyf[gn]
        lsb = getattr(g, "xMin", 0) if g.numberOfContours else 0
        metrics[gn] = (advances[gn], lsb)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
    fb.setupNameTable({
        "familyName": "SpikeSegment",
        "styleName": "Regular",
        "uniqueFontIdentifier": "SpikeSegment-Regular;1.000",
        "fullName": "SpikeSegment Regular",
        "psName": "SpikeSegment-Regular",
        "version": "Version 1.000",
    })
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, sTypoLineGap=0,
                usWinAscent=ASCENT, usWinDescent=-DESCENT, achVendID="SPKE",
                fsType=0, usWeightClass=400, sxHeight=500, sCapHeight=H)
    fb.setupPost()
    fb.save(path)


# ---------------------------------------------------------------- sounds
RATE = 44100


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", s) for s in samples))


def quiet_beep(seconds=0.4, freq=660.0, amplitude=0.02):
    n = int(RATE * seconds)
    fade = int(RATE * 0.05)
    out = []
    for i in range(n):
        env = min(1.0, i / fade, (n - 1 - i) / fade)
        out.append(int(32767 * amplitude * env * math.sin(2 * math.pi * freq * i / RATE)))
    return out


# ---------------------------------------------------------------- icon
def build_icon(path):
    img = Image.new("RGB", (1024, 1024), (28, 28, 30))
    d = ImageDraw.Draw(img)
    d.ellipse((152, 152, 872, 872), outline=(80, 80, 84), width=70)
    d.arc((152, 152, 872, 872), start=-90, end=150, fill=(255, 149, 0), width=70)
    # a crude "S" made of bars, so the icon is recognisable as the spike
    for box in [(392, 372, 632, 422), (392, 487, 632, 537), (392, 602, 632, 652),
                (392, 372, 442, 537), (582, 487, 632, 652)]:
        d.rectangle(box, fill=(255, 255, 255))
    img.save(path, "PNG")


def main():
    fonts = os.path.join(ROOT, "Resources", "Fonts")
    sounds = os.path.join(ROOT, "Resources", "Sounds")
    icon_dir = os.path.join(ROOT, "App", "Assets.xcassets", "AppIcon.appiconset")
    for d in (fonts, sounds, icon_dir):
        os.makedirs(d, exist_ok=True)
    build_font(os.path.join(fonts, "SpikeSegment.ttf"))
    write_wav(os.path.join(sounds, "quiet.wav"), quiet_beep())
    write_wav(os.path.join(sounds, "silent.wav"), [0] * RATE)
    build_icon(os.path.join(icon_dir, "AppIcon-1024.png"))
    print("assets written under", ROOT)


if __name__ == "__main__":
    main()
