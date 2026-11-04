#!/usr/bin/env python3
"""Lay two animated GIFs side by side into one, labelled Avant / Après.

    merge-gifs.py <avant.gif> <apres.gif> <out.gif> [--width 1440] [--fps 5] [--labels "Avant,Après"]
                  [--caption "what changed, one sentence"] [--highlight x,y,w,h] [--viewport-width W]

The fallback of merge-videos.py when ffmpeg is missing: same options, same layout, no dissolve.

Each clip is scaled to half the output width, the shorter clip holds its last
frame until the longer one ends, and a label strip sits above each half.
Needs Pillow (`python3 -m pip install --user Pillow`).
"""
import argparse
import sys

from PIL import Image, ImageDraw, ImageFont, ImageSequence


def load(path, fps):
    """Return the clip's frames resampled at `fps`, as RGB images."""
    im = Image.open(path)
    frames, durations = [], []
    for frame in ImageSequence.Iterator(im):
        frames.append(frame.convert("RGB"))
        durations.append(frame.info.get("duration", 100) or 100)
    # Walk the source timeline and pick the frame shown at each output tick.
    step = 1000 / fps
    out, t, i, elapsed = [], 0.0, 0, 0.0
    total = sum(durations)
    while t < total:
        while i < len(durations) - 1 and t >= elapsed + durations[i]:
            elapsed += durations[i]
            i += 1
        out.append(frames[i])
        t += step
    return out or frames[:1]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("avant")
    p.add_argument("apres")
    p.add_argument("out")
    p.add_argument("--width", type=int, default=1440, help="total output width")
    p.add_argument("--fps", type=int, default=5)
    p.add_argument("--labels", default="Avant,Après")
    p.add_argument("--caption", default="")
    p.add_argument("--highlight", default="", help="x,y,w,h of the changed element on the Après side")
    p.add_argument("--viewport-width", type=float, default=0, help="window.innerWidth when the rectangle was measured")
    a = p.parse_args()
    highlight = tuple(float(v) for v in a.highlight.split(",")) if a.highlight else None
    if highlight and a.viewport_width:
        ratio = Image.open(a.apres).size[0] / a.viewport_width
        highlight = tuple(v * ratio for v in highlight)

    left, right = load(a.avant, a.fps), load(a.apres, a.fps)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", max(28, a.width // 40) - 10)
    except OSError:
        font = ImageFont.load_default()
    half = a.width // 2
    gap = 8
    strip = max(28, a.width // 40)

    def fit(frame):
        w, h = frame.size
        return frame.resize((half, round(h * half / w)), Image.LANCZOS)

    source_width = right[0].size[0]
    left, right = [fit(f) for f in left], [fit(f) for f in right]
    if highlight:
        x, y, w, h = (v * half / source_width for v in highlight)
        ImageDraw.Draw(right[-1]).rounded_rectangle(
            (x - 6, y - 6, x + w + 6, y + h + 6), radius=8, outline="#F59E0B", width=4
        )
    caption_lines = []
    if a.caption:
        line = ""
        for word in a.caption.split():
            trial = f"{line} {word}".strip()
            if font.getlength(trial) > a.width - 40 and line:
                caption_lines.append(line)
                line = word
            else:
                line = trial
        caption_lines.append(line)
    caption_height = 16 + (strip - 4) * len(caption_lines) if caption_lines else 0
    height = max(max(f.size[1] for f in left), max(f.size[1] for f in right))
    n = max(len(left), len(right))
    labels = a.labels.split(",")

    frames = []
    for k in range(n):
        canvas = Image.new("RGB", (a.width + gap, height + strip + caption_height), "#111111")
        draw = ImageDraw.Draw(canvas)
        for j, l in enumerate(caption_lines):
            draw.text((20, height + strip + 8 + (strip - 4) * j), l, fill="#F5F5F5", font=font)
        for col, (clip, label) in enumerate(zip((left, right), labels)):
            x = col * (half + gap)
            draw.text((x + 10, 6), label, fill="white", font=font)
            canvas.paste(clip[min(k, len(clip) - 1)], (x, strip))
        frames.append(canvas.quantize(colors=128, method=Image.Quantize.FASTOCTREE))

    frames[0].save(
        a.out,
        save_all=True,
        append_images=frames[1:],
        duration=round(1000 / a.fps),
        loop=0,
        optimize=True,
    )
    print(f"{a.out}: {n} frames, {a.width + gap}x{height + strip}", file=sys.stderr)


if __name__ == "__main__":
    main()
