# The Market Papers — UI Assets

Drop the contents of `grunge/` into `res://textures/grunge/` in your Godot
project. The full design reference is provided in both vector (SVG, editable)
and raster (PNG, 2400px wide) form.

## Files

### Full design
- `design_reference.svg` — the complete mockup, vector, editable in Inkscape/
  Figma/Affinity. Edit colors, swap text, add elements.
- `design_reference.png` — same mockup rasterized at 2400px wide for quick
  reference or print.

### Grunge layer (drop into res://textures/grunge/)
- `coffee_stain.png` — 480x360, modulate.a recommended around 0.72
- `fold_vertical.png` — 64x1600, tile or stretch vertically, alpha ~0.18
- `fold_horizontal.png` — 2400x48, stretch horizontally, alpha ~0.12
- `smudge_01.png` ... `smudge_04.png` — small irregular blobs, alpha ~0.45,
  rotate randomly between -20deg and +20deg for variety
- `stamp_trader_edition.png` — 220x220 circular stamp, alpha ~0.55,
  rotate -14deg, place top-right
- `stamp_open.png` — 260x ~64, alpha ~0.85, rotate -9deg, sits on the
  active article card
- `stamp_archived.png` — bonus variant for read-but-unopened cards,
  alpha ~0.7, rotate -6deg

All SVG sources sit beside their PNGs so you can re-export at different sizes
or recolor in your editor of choice. Recolor in Godot is also one line:
`texture_rect.modulate = Color(...)` will tint any of these.

## Tip
The grunge assets were rendered at 2x display size so they stay crisp at game
render scale. If you ship at 4K, re-render the SVGs at 4x via:

    cairosvg input.svg -o output.png --output-width 1280
