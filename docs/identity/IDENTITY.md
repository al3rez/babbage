# Babbage identity

The project is named after Charles Babbage (1791–1871), who designed the Difference and
Analytical Engines. The portrait is the logo, the way [Bergamota](https://github.com/ry-diffusion/Bergamota)
uses Newton and IDA uses Ada Lovelace; this identity follows Bergamota's (`tools/identity` there).

- **Face:** Charles Babbage, photograph of 1860 (unknown photographer, public domain;
  Wikimedia Commons, "File:Charles Babbage - 1860.jpg"). Cut out (`babbage-cutout.png`, 1280 px
  wide, made with rembg's BiRefNet-portrait model) and printed as a black-and-white round-dot
  halftone: 6.5 px cells at 45° on the 1280 px master, ink `#161616` on paper `#f4f3ec`, each
  cell's average tone (not single pixels, so no film grain) through a 1.7 gamma so the lit face
  keeps its dots; the largest dots stop short of merging, so the hair keeps texture.
- **Ground:** the menu bar's sky blue `#2f66fd` (from the wallpaper behind the bar), with a 40 × 40
  grid of dots `#2456e8`.
- **Numerals:** a giant white "13" (Debian 13) behind the head, Archivo Black 900, width 112
  (Archivo is under the SIL Open Font License: `Archivo-OFL.txt`).
- **Shape:** macOS rounded square, an 824 px body in a 1024 canvas, radius 185, soft shadow.

`python3 docs/identity/mkicon.py` (needs Pillow) rebuilds `icon-1024.png`, `icon-512.png` and
`babbage-halftone.png` from the cutout.
