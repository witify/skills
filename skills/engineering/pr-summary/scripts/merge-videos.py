#!/usr/bin/env python3
"""Lay two recordings (animated GIFs) side by side into one mp4, labelled Avant / Après.

    merge-videos.py <avant.gif> <apres.gif> <out.mp4> [--width 1440] [--fade 0.5] [--min-hold 1.2]
                    [--labels "Avant,Après"] [--caption "what changed, one sentence"]
                    [--highlight x,y,w,h] [--viewport-width W] [--highlight-color "#F59E0B"]

`--caption` writes the sentence in a strip under the video, so the viewer knows
what to look for. `--highlight` draws a frame around the changed element on the
Après side, on its final state only: x,y,w,h are the element's viewport pixels
at the time of the last capture (`element.getBoundingClientRect()`). The
recording is often smaller than the viewport (Chrome scales the capture), so
pass `--viewport-width` (`window.innerWidth` at measurement time) and the
rectangle is scaled from CSS pixels to the recording's pixels.

Each recording is a handful of states (one frame per action); the video shows
each state for at least `--min-hold` seconds and dissolves between states over
`--fade` seconds, so the result plays smoothly instead of jumping. Each side is
scaled to half the width, the shorter side holds its last state until the
longer one ends, and a label strip sits above each half.
Needs ffmpeg (`brew install ffmpeg`) and Pillow (`python3 -m pip install --user Pillow`).
The labels are drawn by Pillow, so ffmpeg needs no drawtext (Homebrew's build has none).
"""
import argparse
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont, ImageSequence

FONT = "/System/Library/Fonts/Helvetica.ttc"


def load_font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def draw_highlight(image, rect, scale, color):
    """Frame the changed element: a rounded outline, 4px, slightly larger than the element."""
    x, y, w, h = (v * scale for v in rect)
    pad = 6
    ImageDraw.Draw(image).rounded_rectangle(
        (x - pad, y - pad, x + w + pad, y + h + pad), radius=8, outline=color, width=4
    )


def frames(gif, folder, name, min_hold, half, strip, label, highlight=None, color="#F59E0B"):
    """Write the GIF's frames as labelled PNGs, half the output wide; return [(path, seconds)].

    `highlight` (x, y, w, h in the GIF's pixels) is drawn on the last frame only.
    """
    font = load_font(strip - 12)
    source = list(ImageSequence.Iterator(Image.open(gif)))
    out = []
    for i, frame in enumerate(source):
        rgb = frame.convert("RGB")
        w, h = rgb.size
        scale = half / w
        rgb = rgb.resize((half, round(h * scale)), Image.LANCZOS)
        if highlight and i == len(source) - 1:
            draw_highlight(rgb, highlight, scale, color)
        canvas = Image.new("RGB", (half, rgb.size[1] + strip), "#111111")
        ImageDraw.Draw(canvas).text((12, 6), label, fill="white", font=font)
        canvas.paste(rgb, (0, strip))
        path = folder / f"{name}-{i:03d}.png"
        canvas.save(path)
        out.append((path, max(min_hold, (frame.info.get("duration") or 100) / 1000)))
    return out


def caption_image(text, width, path):
    """A strip the full width of the video with the caption wrapped inside it."""
    font = load_font(26)
    words, lines, line = text.split(), [], ""
    for word in words:
        trial = f"{line} {word}".strip()
        if font.getlength(trial) > width - 40 and line:
            lines.append(line)
            line = word
        else:
            line = trial
    lines.append(line)
    height = 20 + 34 * len(lines)
    height += height % 2
    image = Image.new("RGB", (width, height), "#111111")
    draw = ImageDraw.Draw(image)
    for k, l in enumerate(lines):
        draw.text((20, 12 + 34 * k), l, fill="#F5F5F5", font=font)
    image.save(path)


def side(items, index, fade):
    """Return (input args, filter lines, output label, duration) for one side."""
    args, lines, n = [], [], len(items)
    for k, (path, hold) in enumerate(items):
        args += ["-loop", "1", "-t", f"{hold + fade:.3f}", "-i", str(path)]
        lines.append(
            f"[{index + k}:v]setsar=1,fps=30,format=yuv420p[s{index}_{k}]"
        )
    prev, offset = f"s{index}_0", 0.0
    for k in range(1, n):
        offset += items[k - 1][1]
        lines.append(
            f"[{prev}][s{index}_{k}]xfade=transition=fade:duration={fade}:offset={offset:.3f}[x{index}_{k}]"
        )
        prev = f"x{index}_{k}"
    total = sum(h for _, h in items) + fade
    return args, lines, prev, total


def main():
    p = argparse.ArgumentParser()
    p.add_argument("avant")
    p.add_argument("apres")
    p.add_argument("out")
    p.add_argument("--width", type=int, default=1440)
    p.add_argument("--fade", type=float, default=0.5)
    p.add_argument("--min-hold", type=float, default=1.2)
    p.add_argument("--labels", default="Avant,Après")
    p.add_argument("--caption", default="", help="what changed, one sentence, written under the video")
    p.add_argument("--highlight", default="", help="x,y,w,h of the changed element on the Après side")
    p.add_argument("--viewport-width", type=float, default=0, help="window.innerWidth when the rectangle was measured")
    p.add_argument("--highlight-color", default="#F59E0B")
    a = p.parse_args()
    highlight = tuple(float(v) for v in a.highlight.split(",")) if a.highlight else None
    if highlight and a.viewport_width:
        ratio = Image.open(a.apres).size[0] / a.viewport_width
        highlight = tuple(v * ratio for v in highlight)

    half = a.width // 2 - 4
    strip = max(32, a.width // 36)
    labels = a.labels.split(",")
    with tempfile.TemporaryDirectory() as tmp:
        folder = pathlib.Path(tmp)
        left = frames(a.avant, folder, "avant", a.min_hold, half, strip, labels[0])
        right = frames(a.apres, folder, "apres", a.min_hold, half, strip, labels[1], highlight, a.highlight_color)
        args_l, lines_l, out_l, dur_l = side(left, 0, a.fade)
        args_r, lines_r, out_r, dur_r = side(right, len(left), a.fade)
        longest = max(dur_l, dur_r)
        lines = lines_l + lines_r
        for name, dur in ((out_l, dur_l), (out_r, dur_r)):
            lines.append(
                f"[{name}]tpad=stop_mode=clone:stop_duration={longest - dur:.3f},pad=iw+4:ih:0:0:color=#111111[{name}p]"
            )
        lines.append(
            f"[{out_l}p][{out_r}p]scale2ref=iw:ih[l][r];[l][r]hstack=inputs=2,pad=ceil(iw/2)*2:ceil(ih/2)*2[body]"
        )
        args_c = []
        if a.caption:
            cap = folder / "caption.png"
            caption_image(a.caption, 2 * half + 8, cap)
            args_c = ["-loop", "1", "-t", f"{longest:.3f}", "-i", str(cap)]
            lines.append(f"[{len(left) + len(right)}:v]fps=30,format=yuv420p[cap];[body][cap]vstack=inputs=2[v]")
        else:
            lines.append("[body]null[v]")
        cmd = [
            "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
            *args_l, *args_r, *args_c,
            "-filter_complex", ";".join(lines),
            "-map", "[v]", "-t", f"{longest:.3f}",
            "-c:v", "libx264", "-preset", "medium", "-crf", "22",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", a.out,
        ]
        subprocess.run(cmd, check=True)
    size = pathlib.Path(a.out).stat().st_size
    print(f"{a.out}: {longest:.1f}s, {size // 1024} KB", file=sys.stderr)


if __name__ == "__main__":
    main()
