"""Regenerate Android launcher icon assets with smooth rounded corners.

The source lib/assets/icons/ecotrace.png is a full-bleed square badge (opaque
right into its corners). Android re-displays it unmasked during launcher zoom
animations, in Recents/share sheets on some devices, and on pre-API-26
devices via the legacy ic_launcher.png -- all of which expose the hard 90
degree corners.

This script bakes a smooth squircle-style rounding (28% of the artwork side)
into:
  * every legacy mipmap-*/ic_launcher.png  (48..192 px, all densities)
  * every adaptive mipmap-*/ic_launcher_foreground.png (108..432 px canvas)
  * the in-app splash asset lib/assets/icons/ecotrace_icon.png (1024 px)

The adaptive background layers are already a solid dark green (#044921) that
matches the badge fill, so the transparent rounded corners blend seamlessly
under every adaptive mask. The splash asset gets the same treatment so the
icon that drops into the in-app splash screen matches the launcher exactly.
"""

from PIL import Image, ImageDraw, ImageFilter
import os

SRC = r'c:/flutter_workspace/ecotrace/lib/assets/icons/ecotrace.png'
RES = r'c:/flutter_workspace/ecotrace/android/app/src/main/res'
SPLASH_ICON = r'c:/flutter_workspace/ecotrace/lib/assets/icons/ecotrace_icon.png'

DENSITIES = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
}
FOREGROUND_CANVAS_XXXHDPI = 432   # 108 dp at 4x
CONTENT_RATIO = 0.5162            # keep the current foreground art size (223 px art on 432 px canvas)
CORNER_RADIUS_FRAC = 0.28         # Pixel-squircle style rounding
LEGACY_FILL_FRAC = 0.92           # legacy full-bleed icons keep a small margin
SPLASH_SIZE = 1024                # in-app splash icon canvasing (256 dp class, crisp at 160 display px)
SPLASH_FILL_FRAC = 0.92


def rounded_mask(size, radius):
    """High-quality anti-aliased rounded-rectangle alpha mask."""
    ss = 8  # supersample factor
    S = size * ss
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=radius * ss, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def make_icon(art, canvas, content_ratio, corner_radius_frac):
    """Place artwork centered on a transparent canvas with rounded corners."""
    out = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    box = int(canvas * content_ratio)
    work = art.copy()
    work.thumbnail((box, box), Image.LANCZOS)
    w, h = work.size
    ox = (canvas - w) // 2
    oy = (canvas - h) // 2
    out.paste(work, (ox, oy), work)

    # Round the artwork's corners with a supersampled rounded mask.
    mask = rounded_mask(w, int(round(w * corner_radius_frac)))
    alpha = out.split()[3]
    # The mask must be placed over the artwork's bounding box only.
    full_alpha = Image.new('L', (canvas, canvas), 0)
    full_alpha.paste(mask, (ox, oy))
    rounded_alpha = Image.composite(alpha, Image.new('L', (canvas, canvas), 0), full_alpha)
    out.putalpha(rounded_alpha)
    return out


def main():
    art = Image.open(SRC).convert('RGBA')

    # ---- Adaptive foregrounds (keep per-density canvas size) -------------
    for den, scale in DENSITIES.items():
        canvas = int(round(FOREGROUND_CANVAS_XXXHDPI * scale / 4.0))
        icon = make_icon(art, canvas, CONTENT_RATIO, CORNER_RADIUS_FRAC)
        path = os.path.join(RES, 'mipmap-%s' % den, 'ic_launcher_foreground.png')
        icon.save(path)
        print('wrote', path, icon.size)

    # ---- Legacy ic_launcher.png (48..192 px) -----------------------------
    legacy_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }
    for den, size in legacy_sizes.items():
        icon = make_icon(art, size, LEGACY_FILL_FRAC, CORNER_RADIUS_FRAC)
        path = os.path.join(RES, 'mipmap-%s' % den, 'ic_launcher.png')
        icon.save(path)
        print('wrote', path, icon.size)

    # ---- In-app splash icon (lib/assets/icons/ecotrace_icon.png) ---------
    splash = make_icon(art, SPLASH_SIZE, SPLASH_FILL_FRAC, CORNER_RADIUS_FRAC)
    splash.save(SPLASH_ICON)
    print('wrote', SPLASH_ICON, splash.size)


if __name__ == '__main__':
    main()