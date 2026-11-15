"""Quotely Play Store promo video, LANDSCAPE 1920x1080, light mode.

The app's Spotlight look: paper background with a soft glow, the phone
recording on the right in an ink frame, captions on the left (a mono
eyebrow with the terracotta dot, an Instrument Serif title, a quiet
subtitle). Adapted from snake_classic's store_listings/play-store-video.

Usage: python render_landscape.py <ffmpeg.exe> <scenes.json> <music> <out.mp4>
"""

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = Path(__file__).parent
APP = D.parents[2]
FONTS = APP / "assets" / "fonts"
FF, SCENES, MUSIC, OUT = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
W, H = 1920, 1080

# Spotlight light tokens (lib/theme/tokens.dart)
PAPER = (243, 238, 229)
INK = (29, 25, 21)
MUTE = (111, 102, 91)
LINE = (220, 211, 196)
ACC = (165, 73, 43)  # terracotta
GLOWS = [(242, 160, 126), (201, 207, 122), (198, 176, 255)]  # clay, moss, lilac

INTRO, OUTRO, FADE = 3.2, 4.8, 0.35

# Phone on the right
PH = 960
PW = round(PH * 1080 / 2340 / 2) * 2
PX, PY = 1210, (H - PH) // 2
RADIUS = 44
BEZEL = 14
CAP_X, CAP_W = 150, 900


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


SERIF = "InstrumentSerif-Regular.ttf"
MONO = "IBMPlexMono-SemiBold.ttf"
SANS = "SchibstedGrotesk-Regular.ttf"
SANS_SEMI = "SchibstedGrotesk-SemiBold.ttf"


def wrap(draw, text, f, width):
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def spaced(draw, xy, text, f, fill, spacing, anchor="lm"):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=f, fill=fill, anchor=anchor)
        x += draw.textlength(ch, font=f) + spacing
    return x


def spaced_width(draw, text, f, spacing):
    return sum(draw.textlength(c, font=f) + spacing for c in text) - spacing


def eyebrow(draw, x, y, label, size=30):
    """The feature graphic's '● QUOTES · SCENES · FACTS' line."""
    r = size * 0.24
    draw.ellipse((x, y - r, x + 2 * r, y + r), fill=ACC)
    spaced(draw, (x + 2 * r + 22, y), label.upper(), font(MONO, size), INK, size * 0.28)


def background():
    img = Image.new("RGB", (W, H), PAPER)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-300, -350, 900, 650), fill=GLOWS[0] + (70,))
    gd.ellipse((300, 600, 1300, 1500), fill=GLOWS[1] + (70,))
    gd.ellipse((1300, -200, 2300, 800), fill=GLOWS[0] + (55,))
    glow = glow.filter(ImageFilter.GaussianBlur(180))
    img.paste(glow, (0, 0), glow)
    return img


def caption_png(i, chip, title, sub):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ft, fs = font(SERIF, 112), font(SANS, 44)
    tlines = wrap(d, title, ft, CAP_W)
    slines = wrap(d, sub, fs, CAP_W - 60)[:3]
    block = 40 + 46 + len(tlines) * 112 + 50 + len(slines) * 62
    y = (H - block) // 2
    eyebrow(d, CAP_X, y + 20, chip)
    y += 40 + 46
    for line in tlines:
        d.text((CAP_X - 4, y), line, font=ft, fill=INK)
        y += 112
    y += 50
    for line in slines:
        d.text((CAP_X, y), line, font=fs, fill=MUTE)
        y += 62
    p = D / f"lcap{i}.png"
    img.save(p)
    return p


def phone_assets():
    bg = background()
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (PX - BEZEL + 10, PY - BEZEL + 30, PX + PW + BEZEL + 10, PY + PH + BEZEL + 30),
        radius=RADIUS + BEZEL, fill=(29, 25, 21, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    bg.paste(shadow, (0, 0), shadow)
    ImageDraw.Draw(bg).rounded_rectangle(
        (PX - BEZEL, PY - BEZEL, PX + PW + BEZEL - 1, PY + PH + BEZEL - 1),
        radius=RADIUS + BEZEL, fill=INK)
    bg.save(D / "lstage.png")
    mask = Image.new("L", (PW, PH), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, PW - 1, PH - 1), radius=RADIUS, fill=255)
    mask.save(D / "lmask.png")


def logo(size):
    return Image.open(APP / "assets" / "brand" / "app" / "logo-512.png").convert("RGBA").resize(
        (size, size), Image.LANCZOS)


def card(name, build):
    img = background()
    d = ImageDraw.Draw(img)
    build(img, d)
    p = D / f"{name}.png"
    img.save(p)
    return p


def intro(img, d):
    lg = logo(240)
    img.paste(lg, ((W - 240) // 2, 190), lg)
    d.text((W / 2, 560), "Quotely", font=font(SERIF, 150), fill=INK, anchor="mm")
    d.text((W / 2, 700), "Wisdom, one line at a time.", font=font(SERIF, 76), fill=INK, anchor="mm")
    label = "QUOTES · SCENES · FACTS"
    f = font(MONO, 32)
    w = spaced_width(d, label, f, 9) + 40
    eyebrow(d, (W - w) / 2, 820, label, 32)


def outro(img, d):
    lg = logo(190)
    img.paste(lg, (170, 170), lg)
    d.text((400, 265), "Quotely", font=font(SERIF, 130), fill=INK, anchor="lm")
    items = ["A quote, a scene and a fact every day", "True or false? A daily facts game",
             "Home-screen widgets", "Works offline. No ads."]
    fi = font(SANS, 46)
    y = 480
    for t in items:
        d.ellipse((182, y - 9, 200, y + 9), fill=ACC)
        d.text((232, y), t, font=fi, fill=INK, anchor="lm")
        y += 92
    bw, bh = 600, 140
    bx, by = 1170, 420
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=bh // 2, fill=INK)
    d.text((bx + bw / 2, by + bh / 2), "Free on Google Play", font=font(SANS_SEMI, 50),
           fill=PAPER, anchor="mm")
    label = "QUOTES · SCENES · FACTS"
    f = font(MONO, 28)
    w = spaced_width(d, label, f, 8) + 34
    eyebrow(d, bx + (bw - w) / 2, by + bh + 70, label, 28)


def main():
    scenes = json.loads(Path(SCENES).read_text(encoding="utf-8"))["segments"]
    phone_assets()
    caps = [caption_png(i, s["chip"], s["title"], s["sub"]) for i, s in enumerate(scenes)]
    intro_p, outro_p = card("lintro", intro), card("loutro", outro)

    durs = [s["b"] - s["a"] for s in scenes]
    demo_len = sum(durs)
    total = INTRO + demo_len + OUTRO

    srcs = sorted({s["src"] for s in scenes})
    inputs, idx = [], {}
    for sp in srcs:
        idx[sp] = len(inputs) // 2
        inputs += ["-i", str(D / sp)]
    n_src = len(srcs)
    inputs += ["-loop", "1", "-i", str(D / "lstage.png")]
    inputs += ["-i", str(D / "lmask.png")]
    inputs += ["-loop", "1", "-t", str(INTRO), "-i", str(intro_p)]
    inputs += ["-loop", "1", "-t", str(OUTRO), "-i", str(outro_p)]
    cap0 = n_src + 4
    for p, du in zip(caps, durs):
        inputs += ["-loop", "1", "-t", f"{du:.3f}", "-i", str(p)]
    music_i = cap0 + len(scenes)
    inputs += ["-i", MUSIC]

    fc = []
    uses = {sp: [i for i, s in enumerate(scenes) if s["src"] == sp] for sp in srcs}
    for sp, ids in uses.items():
        k = idx[sp]
        outs = "".join(f"[r{i}]" for i in ids)
        fc.append(f"[{k}:v]fps=30,split={len(ids)}{outs}" if len(ids) > 1 else f"[{k}:v]fps=30{outs}")
    for i, s in enumerate(scenes):
        fc.append(f"[r{i}]trim={s['a']}:{s['b']},setpts=PTS-STARTPTS[t{i}]")
    fc.append("".join(f"[t{i}]" for i in range(len(scenes))) + f"concat=n={len(scenes)}:v=1:a=0[rec]")
    fc.append(f"[rec]scale={PW}:{PH}:flags=lanczos,format=rgba[ph]")
    fc.append(f"[{n_src + 1}:v]format=gray[mk]")
    fc.append("[ph][mk]alphamerge[phr]")
    fc.append(f"[{n_src}:v]fps=30,trim=0:{demo_len:.3f},setpts=PTS-STARTPTS[stg]")
    fc.append(f"[stg][phr]overlay={PX}:{PY}:shortest=1[a0]")
    last, t = "a0", 0.0
    for i, du in enumerate(durs):
        fades = f"fade=in:st=0:d={FADE}:alpha=1,fade=out:st={du - FADE:.3f}:d={FADE}:alpha=1"
        fc.append(f"[{cap0 + i}:v]format=rgba,{fades},setpts=PTS-STARTPTS+{t:.3f}/TB[c{i}]")
        fc.append(f"[{last}][c{i}]overlay=0:0:eof_action=pass[b{i}]")
        last, t = f"b{i}", t + du
    fc.append(f"color=c=0xA5492B:s={W}x6:r=30:d={demo_len:.3f}[bar]")
    fc.append(f"[{last}][bar]overlay=x='-{W}+{W}*t/{demo_len:.3f}':y={H - 6}:shortest=1,"
              f"format=yuv420p,setsar=1[demo]")
    fc.append(f"[{n_src + 2}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.5,fade=out:st={INTRO - 0.4}:d=0.4,setsar=1[in]")
    fc.append(f"[{n_src + 3}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.4,fade=out:st={OUTRO - 0.8}:d=0.8,setsar=1[out]")
    fc.append("[in][demo][out]concat=n=3:v=1:a=0[v]")
    fc.append(f"[{music_i}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,volume=0.9,"
              f"afade=in:st=0:d=1.0,afade=out:st={total - 2.5:.3f}:d=2.5[aud]")

    cmd = [FF, "-hide_banner", "-loglevel", "error", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", "[v]", "-map", "[aud]", "-t", f"{total:.2f}", "-c:v", "libx264", "-crf", "19",
           "-preset", "slow", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
           "-movflags", "+faststart", OUT]
    subprocess.run(cmd, check=True)
    print("done", round(total, 2))


main()
