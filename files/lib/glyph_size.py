"""Optical size of tray glyphs, so every tray icon looks the same size without hand-tuning.

Used by files/bin/bar-icons (Babbage's glyphs and the icon theme's) and files/bin/menubar-popovers
(any other app's icon, made flat white); on both wrappers' PYTHONPATH (modules/panel.nix). Pure
Python: a glyph is its alpha channel, w x h bytes.

A glyph's optical size is the square root of its silhouette's area (the convex hull of what's
drawn: a ring counts as a disc, a 3x3 grid of dots as a square, a Wi-Fi fan as its wedge), so a
circle, a fan and a grid of the same height don't look different sizes. Solid glyphs look heavier
than outlines, so the ink's share of that area nudges them a little smaller (DENSITY_WEIGHT).
The target is given as the diameter a round outline glyph gets, in bar pixels.
"""
import math

THRESHOLD = 20          # alpha counted as drawn
REFERENCE_DENSITY = 0.5  # ink share of an outline glyph (1Password's ring), drawn at the target as is
DENSITY_WEIGHT = 0.15    # how much heavier a solid glyph looks: optical size x (density / reference)^this
MARGIN = 1              # px kept free on each side of the tray slot
DEFAULT_TARGET = 23     # px across a round glyph (1Password's) is drawn at, unless icon-sizes.json sets tray-size


def measure(alpha, w, h):
    """{bbox: (x0, y0, x1, y1), centre: (cx, cy), hull: area, density: ink / hull} of a glyph, in
    its own pixels; None if nothing is drawn."""
    left, right = {}, {}
    ink = 0
    for y in range(h):
        row = alpha[y * w:(y + 1) * w]
        for x, a in enumerate(row):
            if a > THRESHOLD:
                ink += a / 255
                if y not in left:
                    left[y] = x
                right[y] = x
    if not left:
        return None
    # convex hull of each row's ends (pixel corners), monotone chain
    points = sorted({p for y in left for p in ((left[y], y), (left[y], y + 1), (right[y] + 1, y), (right[y] + 1, y + 1))})

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    hull = lower[:-1] + upper[:-1]
    area = abs(sum(hull[i][0] * hull[i - 1][1] - hull[i - 1][0] * hull[i][1] for i in range(len(hull)))) / 2
    x0, x1 = min(left.values()), max(right.values()) + 1
    y0, y1 = min(left), max(left) + 1
    return {"bbox": (x0, y0, x1, y1), "centre": ((x0 + x1) / 2, (y0 + y1) / 2),
            "hull": max(area, 1.0), "density": min(1.0, ink / max(area, 1.0))}


def optical(m):
    """Optical size of a measured glyph, in its own pixels."""
    return math.sqrt(m["hull"]) * (m["density"] / REFERENCE_DENSITY) ** DENSITY_WEIGHT


def auto_scale(m, target, slot, px_per_bar_px=1.0):
    """The factor to draw a measured glyph by so its optical size matches a round outline glyph
    `target` bar px across, fitting the `slot` px tray slot. The factor maps the measured glyph's
    pixels to pixels of the result, which has `px_per_bar_px` per bar pixel."""
    disc = math.sqrt(math.pi) / 2 * target * px_per_bar_px   # sqrt(area) of a disc `target` across
    k = disc / optical(m)
    x0, y0, x1, y1 = m["bbox"]
    room = (slot - 2 * MARGIN) * px_per_bar_px
    return min(k, room / (x1 - x0), room / (y1 - y0))
