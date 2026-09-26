"""Composes every Quotely brand asset (Spotlight "Paper" identity).

The mark is the opening quote (U+201C) of Instrument Serif, the app's display
face; the ground is warm paper with a peach glow top-right and a faint blue one
bottom-left, the same light the in-app backdrops use. This script only decides
scale, placement and ground: change a number here and re-run, never hand-edit
the output.

    python tools/compose_brand_assets.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

Then check `git diff ios/Runner.xcodeproj/project.pbxproj` is empty (see
assets/brand/README.md).
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = os.path.join(APP, 'assets', 'brand')
SERIF = os.path.join(APP, 'assets', 'fonts', 'InstrumentSerif-Regular.ttf')
S = 1024

PAPER, INK = '#F3EEE5', '#1D1915'
NIGHT, CREAM = '#15120F', '#EEE7DB'

def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def glow(img, color, center, radius, strength):
    w, h = img.size
    k = w / S
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    cx, cy, r = center[0] * k, center[1] * k, radius * k
    ImageDraw.Draw(layer).ellipse([cx - r, cy - r, cx + r, cy + r], fill=hexc(color, int(255 * strength)))
    layer = layer.filter(ImageFilter.GaussianBlur(r * 0.55))
    return Image.alpha_composite(img, layer)

def ground(dark=False, size=S):
    if dark:
        img = Image.new('RGBA', (size, size), hexc(NIGHT))
        img = glow(img, '#C0643F', (820, 180), 520, 0.55)
        return glow(img, '#3F7EC4', (120, 960), 420, 0.22)
    img = Image.new('RGBA', (size, size), hexc(PAPER))
    img = glow(img, '#F2A07E', (820, 180), 520, 0.45)
    return glow(img, '#9CCBFF', (140, 950), 420, 0.25)

_ink_cache = {}
def mark_ink(color):
    """The quote mark as a tight RGBA crop of its actual pixels."""
    if color not in _ink_cache:
        font = ImageFont.truetype(SERIF, 1600)
        big = Image.new('RGBA', (3000, 3000), (0, 0, 0, 0))
        ImageDraw.Draw(big).text((700, 300), '\u201c', font=font, fill=hexc(color))
        _ink_cache[color] = big.crop(big.getbbox())
    return _ink_cache[color]

def place(canvas, color, width_frac, dy_frac=0.02):
    """Centre the mark on [canvas] at [width_frac] of its width. Quote marks
    sit high in the line, so nudge down a touch for optical centre."""
    w, h = canvas.size
    m = mark_ink(color)
    tw = int(w * width_frac)
    th = int(m.height * tw / m.width)
    m = m.resize((tw, th), Image.LANCZOS)
    out = canvas.copy()
    out.alpha_composite(m, ((w - tw) // 2, (h - th) // 2 + int(h * dy_frac)))
    return out

def rounded(im):
    w = im.width
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, w - 1], radius=int(w * 0.225), fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

def circle(im):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).ellipse([0, 0, im.width - 1, im.height - 1], fill=255)
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

def save(im, rel, size=None, rgb=False):
    path = os.path.join(B, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if size:
        im = im.resize((size, size) if isinstance(size, int) else size, Image.LANCZOS)
    (im.convert('RGB') if rgb else im).save(path, optimize=True)

# Mark width as a fraction of the visible tile. Android's adaptive layer is
# 108dp showing the middle 72dp, so there the same visual size is
# MARK_W * 72/108 of the layer.
MARK_W = 0.42
ADAPTIVE_W = round(MARK_W * 72 / 108, 3)

light = place(ground(), INK, MARK_W)
dark = place(ground(True), CREAM, MARK_W)

# master
save(light, r'master\quotely-icon-light-square-1024.png', rgb=True)
save(dark, r'master\quotely-icon-dark-square-1024.png', rgb=True)
save(rounded(light), r'master\quotely-icon-light-1024.png')
save(rounded(dark), r'master\quotely-icon-dark-1024.png')
bare = Image.new('RGBA', (S, S), (0, 0, 0, 0))
save(place(bare, INK, 0.70, 0), r'master\quotely-mark-ink-1024.png')
save(place(bare, CREAM, 0.70, 0), r'master\quotely-mark-cream-1024.png')

# android
A = 432
save(ground(size=A), r'android\adaptive\ic_launcher_background.png')
fg_bare = Image.new('RGBA', (A, A), (0, 0, 0, 0))
# Adaptive safe zone is the central 66/108; keep the mark well inside it.
save(place(fg_bare, INK, ADAPTIVE_W), r'android\adaptive\ic_launcher_foreground.png')
save(place(fg_bare, CREAM, ADAPTIVE_W), r'android\adaptive\ic_launcher_foreground_dark.png')
save(place(fg_bare, '#FFFFFF', ADAPTIVE_W), r'android\adaptive\ic_launcher_monochrome.png')
for d, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(rounded(light), rf'android\mipmap-{d}\ic_launcher.png', px)
    save(circle(light), rf'android\mipmap-{d}\ic_launcher_round.png', px)
for d, px in [('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96)]:
    n = Image.new('RGBA', (px * 4, px * 4), (0, 0, 0, 0))
    save(place(n, '#FFFFFF', 0.86, 0), rf'android\drawable-{d}\ic_notification.png', px)
save(light, r'android\playstore-icon-512.png', 512, rgb=True)

# ios (square, opaque: iOS applies the mask)
for px in [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180]:
    save(light, rf'ios\AppIcon-{px}.png', px, rgb=True)
save(light, r'ios\AppIcon-1024.png', rgb=True)
# iOS 18 dark and tinted: transparent, glyph only; iOS supplies the ground.
save(place(Image.new('RGBA', (S, S), (0, 0, 0, 0)), CREAM, MARK_W), r'ios\AppIcon-1024-dark.png')
save(place(Image.new('RGBA', (S, S), (0, 0, 0, 0)), '#FFFFFF', MARK_W), r'ios\AppIcon-1024-tinted.png')

# splash: the icon's own ground in both appearances, so tapping the icon and
# landing on the splash reads as one surface. Logo only, no branding.
# - splash-background: the glow ground, portrait, used as background_image
# - splash-mark-1024: 4x asset (px / 4 = dp), mark at 40% -> ~100dp
# - android12-mark-1152: Android 12+ draws this inside a 768px circle and
#   crops rather than scales, so keep the mark well inside it
for w, h in [(1284, 2778)]:
    bg = Image.new('RGBA', (w, h), hexc(PAPER))
    bg = glow(bg, '#F2A07E', (820 * w / S, 420), 900, 0.40)
    bg = glow(bg, '#9CCBFF', (120 * w / S, 2500 * S / w), 700, 0.22)
    save(bg, r'splash\splash-background-1284x2778.png', rgb=True)
save(place(Image.new('RGBA', (S, S), (0, 0, 0, 0)), INK, 0.40, 0), r'splash\splash-mark-1024.png')
save(place(Image.new('RGBA', (1152, 1152), (0, 0, 0, 0)), INK, 0.36, 0), r'splash\android12-mark-1152.png')

# wordmarks and lockups, set in the display serif
def wordmark(w, h, color, bg=None):
    im = Image.new('RGBA', (w, h), hexc(bg) if bg else (0, 0, 0, 0))
    font = ImageFont.truetype(SERIF, int(h * 0.78))
    d = ImageDraw.Draw(im)
    l, t, r, b = d.textbbox((0, 0), 'Quotely', font=font)
    d.text(((w - (r - l)) / 2 - l, (h - (b - t)) / 2 - t), 'Quotely', font=font, fill=hexc(color))
    return im

save(wordmark(1200, 360, INK), r'logo\wordmark-ink-1200x360.png')
save(wordmark(1200, 360, CREAM), r'logo\wordmark-cream-1200x360.png')
for name, bg, col, icon in [('light', PAPER, INK, light), ('dark', NIGHT, CREAM, dark)]:
    lock = Image.new('RGBA', (1600, 400), hexc(bg))
    lock.alpha_composite(rounded(icon).resize((280, 280), Image.LANCZOS), (80, 60))
    font = ImageFont.truetype(SERIF, 250)
    d = ImageDraw.Draw(lock)
    l, t, r, b = d.textbbox((0, 0), 'Quotely', font=font)
    d.text((420 - l, (400 - (b - t)) / 2 - t), 'Quotely', font=font, fill=hexc(col))
    save(lock, rf'logo\lockup-{name}-1600x400.png', rgb=True)

# The only brand files the app loads at runtime; everything else is a
# build-time input and is not bundled.
save(rounded(light), r'app\logo-512.png', 512)
save(circle(light), r'app\avatar-256.png', 256)

# Files from the previous identity that nothing uses any more.
for rel in [r'master\quotely-mark-violet-1024.png', r'master\quotely-mark-white-1024.png',
            r'master\quotely-avatar-1024.png',
            r'logo\wordmark-violet-1200x360.png', r'logo\wordmark-white-1200x360.png',
            r'logo\lockup-on-violet-1600x400.png',
            r'splash\splash-logo-light-512.png', r'splash\splash-logo-dark-512.png',
            r'splash\android12-icon-light-1152.png', r'splash\android12-icon-dark-1152.png',
            r'splash\splash-light-1080x1920.png', r'splash\splash-dark-1080x1920.png',
            r'splash\splash-light-1284x2778.png', r'splash\splash-dark-1284x2778.png',
            r'splash\branding-light-800x240.png', r'splash\branding-dark-800x240.png']:
    p = os.path.join(B, rel)
    if os.path.exists(p):
        os.remove(p)
        print('removed', rel)
print('done')

