"""Frames from record.mjs -> an animated WebP (plays in any browser), one frame per 400 ms, real time.
Usage: python make_video.py <frames-dir> <out.webp>
"""
import sys
from pathlib import Path

from PIL import Image

frames = [Image.open(p).convert("RGB") for p in sorted(Path(sys.argv[1]).glob("*.jpg"))]
durations = [400] * len(frames)
durations[-1] = 3000   # hold the last frame
frames[0].save(sys.argv[2], save_all=True, append_images=frames[1:], duration=durations, loop=0, quality=70, method=4)
print(f"{len(frames)} frames, {sum(durations) / 1000:.0f} s -> {sys.argv[2]}")
