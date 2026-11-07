#!/usr/bin/env python3
"""Babbage's icon (docs/identity/IDENTITY.md), after Bergamota's identity (ry-diffusion/Bergamota,
tools/identity): a public-domain portrait as a black-and-white halftone cutout on a dotted ground,
a giant white "13" (Debian 13) behind the head, in a macOS rounded square (824 px body in a
1024 canvas, radius 185, soft shadow). Needs Pillow.
  python3 docs/identity/mkicon.py      # rewrites icon-1024.png, icon-512.png, babbage-halftone.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
CUT, OUT = os.path.join(HERE, "babbage-cutout.png"), HERE
S = 1024
BODY, BX, BY, R = 824, 100, 92, 185
GROUND, DOTS = (47, 102, 253), (36, 86, 232)        # the menu bar's sky blue, dots a shade deeper
WHITE, INK, PAPER = (255, 255, 255), (22, 22, 22), (244, 243, 236)
CELL = 6.5                                           # halftone cell at the figure's 1280 px master width

def halftone(cut):
    """Round-dot halftone of the cutout: paper where light, ink dots growing with darkness."""
    w = 1280
    cut = cut.resize((w, round(cut.height * w / cut.width)), Image.LANCZOS)
    alpha = cut.split()[3].point(lambda v: max(0, min(255, (v - 70) * 255 // 120)))   # crisp cut edge, no grey halo
    g = ImageOps.autocontrast(cut.convert("L"), cutoff=1)
    # gamma keeps dots in the lit face (no blown-out paper), a little contrast keeps the coat black
    g = g.point(lambda v: max(0, min(255, int(255 * (v / 255) ** 1.7))))
    g = g.filter(ImageFilter.GaussianBlur(CELL * 0.45))   # a cell's average tone, not one grainy pixel
    SS = 4                                            # draw dots supersampled, then reduce
    big = Image.new("L", (w * SS, cut.height * SS), 255)
    d = ImageDraw.Draw(big)
    px = g.load(); W, H = g.size
    a = math.radians(45); ca, sa = math.cos(a), math.sin(a)
    n = int(max(W, H) * 1.5 / CELL)
    cx, cy = W / 2, H / 2
    for j in range(-n, n):
        for i in range(-n, n):
            u, v = i * CELL, j * CELL
            x, y = cx + u * ca - v * sa, cy + u * sa + v * ca
            if not (0 <= x < W and 0 <= y < H):
                continue
            dark = 1 - px[int(x), int(y)] / 255
            if dark < 0.04:
                continue
            r = CELL * 0.64 * math.sqrt(dark)            # area ~ darkness; corners stay paper, so shadows keep texture
            d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], fill=0)
    tone = big.resize((W, H), Image.LANCZOS)
    fig = Image.composite(Image.new("RGB", (W, H), PAPER), Image.new("RGB", (W, H), INK), tone)
    fig.putalpha(alpha)
    return fig

def icon(fig):
    body = Image.new("RGB", (BODY, BODY), GROUND)
    d = ImageDraw.Draw(body)
    g = BODY / 40                                    # Bergamota's 40 x 40 ground dots
    for j in range(40):
        for i in range(40):
            x, y = (i + .5) * g, (j + .5) * g
            d.ellipse([x - g * .17, y - g * .17, x + g * .17, y + g * .17], fill=DOTS)
    # giant "13" (Debian 13) behind the head, Archivo black, slightly expanded
    f = ImageFont.truetype(os.path.join(HERE, "Archivo.ttf"), NUMSIZE)
    f.set_variation_by_axes([900, 112])
    txt = "13"
    l, t, r, b = d.textbbox((0, 0), txt, font=f)
    d.text(((BODY - (r - l)) / 2 - l, NUMTOP - t), txt, font=f, fill=WHITE)
    # the figure: head and shoulders, coat running off the bottom edge
    fw = FIGW
    fig = fig.resize((fw, round(fig.height * fw / fig.width)), Image.LANCZOS)
    body.paste(fig, (FIGX, FIGY), fig)
    mask = Image.new("L", (BODY * 4, BODY * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, BODY * 4 - 1, BODY * 4 - 1], radius=R * 4, fill=255)
    mask = mask.resize((BODY, BODY), Image.LANCZOS)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sh = Image.new("L", (S, S), 0); sh.paste(mask, (BX, BY + 14))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0)); shadow.putalpha(sh.filter(ImageFilter.GaussianBlur(14)).point(lambda v: v * 0.28))
    canvas = Image.alpha_composite(canvas, shadow)
    b = body.convert("RGBA"); b.putalpha(mask)
    canvas.alpha_composite(b, (BX, BY))
    return canvas

# figure width and offset in the body (head centred), numeral size and top
FIGW, FIGX, FIGY, NUMSIZE, NUMTOP = 1060, -182, 215, 540, 40
cut = Image.open(CUT).convert("RGBA")
bb = cut.split()[3].point(lambda v: 255 if v > 40 else 0).getbbox()
cut = cut.crop(bb)
fig = halftone(cut)
fig.save(f"{OUT}/babbage-halftone.png")
ic = icon(fig)
ic.save(f"{OUT}/icon-1024.png")
ic.resize((512, 512), Image.LANCZOS).save(f"{OUT}/icon-512.png")
print("wrote", OUT)
