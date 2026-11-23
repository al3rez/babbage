#!/usr/bin/env python3
"""Boot menu splash for the ISO (GRUB on UEFI, isolinux on BIOS), in the identity's colours
(docs/identity/IDENTITY.md): the menu bar's sky blue with its dot grid, and the icon on top.
Run from anywhere (needs Pillow); writes iso/live/config/bootloaders/*/splash.png."""
from pathlib import Path

from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
W, H = 640, 480  # isolinux's size; GRUB scales it to its 800x600 mode

img = Image.new("RGB", (W, H), "#2f66fd")
draw = ImageDraw.Draw(img)
step = W // 40
for y in range(step // 2, H, step):
    for x in range(step // 2, W, step):
        draw.ellipse((x - 1, y - 1, x + 1, y + 1), fill="#2456e8")

icon = Image.open(root.parent / "docs/identity/icon-512.png").convert("RGBA").resize((200, 200), Image.LANCZOS)
img.paste(icon, ((W - 200) // 2, 36), icon)  # above the menu, which starts at 52%

for loader in ("grub-pc", "syslinux_common"):
    out = root / "live/config/bootloaders" / loader / "splash.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)
    print(out)
