#!/usr/bin/env python3
"""Generate 1024x1024 watchOS app icons for the four games.

watchOS masks icons to a circle, so backgrounds are full-bleed and glyphs sit
inside a circle-safe inset. Everything is drawn at SS x scale and downsampled
with LANCZOS for smooth, anti-aliased edges. Wordless, matching the no-words
premise and the zen/muted art direction.

    python3 Assets/make_app_icons.py
"""
import math
import os
from PIL import Image, ImageDraw

SIZE = 1024
SS = 2                      # supersample factor
S = SIZE * SS
CX = CY = S // 2

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vgrad(top, bottom):
    """Vertical gradient background, full-bleed."""
    img = Image.new("RGB", (S, S), top)
    px = img.load()
    for y in range(S):
        c = lerp(top, bottom, y / (S - 1))
        for x in range(S):
            px[x, y] = c
    return img


def rrect(draw, box, r, fill):
    draw.rounded_rectangle(box, radius=r, fill=fill)


def finish(img, name, folder):
    """Downsample and write PNG into the appiconset, wire up Contents.json."""
    out = img.resize((SIZE, SIZE), Image.LANCZOS)
    dest_dir = os.path.join(ROOT, folder)
    png_path = os.path.join(dest_dir, name)
    out.save(png_path)
    # point Contents.json at the file (single universal 1024 entry)
    contents = (
        '{\n'
        '  "images" : [\n'
        '    {\n'
        '      "filename" : "%s",\n'
        '      "idiom" : "universal",\n'
        '      "platform" : "watchos",\n'
        '      "size" : "1024x1024"\n'
        '    }\n'
        '  ],\n'
        '  "info" : {\n'
        '    "author" : "xcode",\n'
        '    "version" : 1\n'
        '  }\n'
        '}\n' % name
    )
    with open(os.path.join(dest_dir, "Contents.json"), "w") as f:
        f.write(contents)
    print("wrote", png_path)


# ── Memory: two rounded tiles, one flipped to show a matching dot ────────────
def memory():
    img = vgrad((26, 42, 58), (12, 20, 30))          # calm deep teal-indigo
    d = ImageDraw.Draw(img)
    tw, th = int(S * 0.30), int(S * 0.40)
    gap = int(S * 0.05)
    y0 = CY - th // 2
    x_left = CX - tw - gap // 2
    x_right = CX + gap // 2
    r = int(tw * 0.22)
    # face-down tile (muted)
    rrect(d, [x_left, y0, x_left + tw, y0 + th], r, (255, 255, 255, 0))
    rrect(d, [x_left, y0, x_left + tw, y0 + th], r, (86, 112, 140))
    # face-up tile (lighter) with a soft matching dot
    rrect(d, [x_right, y0, x_right + tw, y0 + th], r, (222, 232, 242))
    dot_r = int(tw * 0.26)
    dcx, dcy = x_right + tw // 2, y0 + th // 2
    d.ellipse([dcx - dot_r, dcy - dot_r, dcx + dot_r, dcy + dot_r], fill=(94, 168, 205))
    # subtle matching dot echoed (small) on the face-down tile
    sr = int(tw * 0.12)
    scx, scy = x_left + tw // 2, y0 + th // 2
    d.ellipse([scx - sr, scy - sr, scx + sr, scy + sr], fill=(120, 146, 174))
    finish(img, "MemoryAppIcon.png", "Memory/Memory Watch App/Assets.xcassets/AppIcon.appiconset")


# ── Echo: concentric ripple rings from a center dot ─────────────────────────
def echo():
    img = vgrad((40, 30, 66), (14, 12, 28))          # deep violet
    d = ImageDraw.Draw(img)
    rings = [0.34, 0.26, 0.18]
    cols = [(94, 74, 150), (140, 116, 205), (186, 168, 240)]
    for rad, col in zip(rings, cols):
        rr = int(S * rad)
        w = int(S * 0.028)
        d.ellipse([CX - rr, CY - rr, CX + rr, CY + rr], outline=col, width=w)
    cr = int(S * 0.07)
    d.ellipse([CX - cr, CY - cr, CX + cr, CY + cr], fill=(214, 202, 255))
    finish(img, "EchoAppIcon.png", "Echo/Echo Watch App/Assets.xcassets/AppIcon.appiconset")


# ── Ricochet: a bright ball with a banking trajectory into a target ─────────
def ricochet():
    img = vgrad((18, 30, 54), (8, 12, 26))           # space blue
    d = ImageDraw.Draw(img)
    inset = int(S * 0.22)
    # bank path: start top-left, bounce off right, into lower-left target
    p0 = (inset, inset + int(S * 0.04))
    p1 = (S - inset, CY - int(S * 0.02))
    p2 = (CX - int(S * 0.02), S - inset)
    w = int(S * 0.022)
    d.line([p0, p1], fill=(120, 150, 190), width=w, joint="curve")
    d.line([p1, p2], fill=(120, 150, 190), width=w, joint="curve")
    # target ring at p2
    tr = int(S * 0.11)
    d.ellipse([p2[0] - tr, p2[1] - tr, p2[0] + tr, p2[1] + tr], outline=(90, 200, 120), width=int(S * 0.022))
    tir = int(S * 0.05)
    d.ellipse([p2[0] - tir, p2[1] - tir, p2[0] + tir, p2[1] + tir], fill=(90, 200, 120))
    # the ball at the bounce point
    br = int(S * 0.075)
    d.ellipse([p1[0] - br, p1[1] - br, p1[0] + br, p1[1] + br], fill=(240, 244, 250))
    finish(img, "RicochetAppIcon.png", "Ricochet/Ricochet Watch App/Assets.xcassets/AppIcon.appiconset")


# ── Shatter: rows of bricks, one cracked, with the ball below ───────────────
def shatter():
    img = vgrad((54, 30, 40), (24, 12, 18))          # warm ember
    d = ImageDraw.Draw(img)
    cols, rows = 4, 3
    margin = int(S * 0.20)
    gw = S - margin * 2
    top = int(S * 0.24)
    bh = int(S * 0.085)
    vgap = int(S * 0.035)
    hgap = int(S * 0.03)
    bw = (gw - hgap * (cols - 1)) // cols
    palette = [(206, 116, 96), (210, 150, 92), (196, 128, 108), (216, 160, 104)]
    for row in range(rows):
        y = top + row * (bh + vgap)
        for c in range(cols):
            x = margin + c * (bw + hgap)
            # one brick "shattered": skip it, leave a gap
            if row == 1 and c == 2:
                continue
            rrect(d, [x, y, x + bw, y + bh], int(bh * 0.28), palette[(row + c) % len(palette)])
    # ball below the grid
    br = int(S * 0.065)
    bx, by = CX, top + rows * (bh + vgap) + int(S * 0.10)
    d.ellipse([bx - br, by - br, bx + br, by + br], fill=(245, 236, 224))
    finish(img, "ShatterAppIcon.png", "Shatter/Shatter Watch App/Assets.xcassets/AppIcon.appiconset")


if __name__ == "__main__":
    memory()
    echo()
    ricochet()
    shatter()
    print("done")
