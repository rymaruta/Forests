#!/usr/bin/env python3
"""Fair toe-skirt AssetBench compare."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

REF = Path("/workspace/godot/assets/references/parts/ref-toes.png")
BENCH = Path("/opt/cursor/artifacts/screenshots/bench-part-toes.png")
ART = Path("/opt/cursor/artifacts/screenshots")


def subject_crop(im: Image.Image, pad: int = 16) -> Image.Image:
    a = np.asarray(im).astype(np.float32)
    corners = np.stack([a[8, 8], a[8, -8], a[-8, 8], a[-8, -4]]).mean(0)
    ys, xs = np.where(np.abs(a - corners).sum(2) > 28)
    if len(xs) < 40:
        return im
    return im.crop(
        (
            max(0, int(xs.min()) - pad),
            max(0, int(ys.min()) - pad),
            min(im.width, int(xs.max()) + pad),
            min(im.height, int(ys.max()) + pad),
        )
    )


def stats(im: Image.Image, label: str) -> None:
    a = np.asarray(im).astype(np.float32)
    c = np.stack([a[4, 4], a[4, -4], a[-4, 4], a[-4, -4]]).mean(0)
    pix = a[np.abs(a - c).sum(2) > 28]
    print(
        label,
        "mean",
        np.round(pix.mean(0), 1),
        "p10",
        round(float(np.percentile(pix.mean(1), 10)), 1),
        "aspect",
        round(im.width / im.height, 2),
    )


def main() -> None:
    ref = Image.open(REF).convert("RGB")
    bench = Image.open(BENCH).convert("RGB")
    rc = subject_crop(ref, 8)
    bc = subject_crop(bench, 18)
    bc_fair = bc.resize(
        (max(1, int(bc.width * rc.height / bc.height)), rc.height),
        Image.Resampling.LANCZOS,
    )
    print("toes fair_cmp")
    stats(rc, "REF")
    stats(bc_fair, "NOW")
    H = max(rc.height * 2, 300)

    def fit(im: Image.Image) -> Image.Image:
        r = H / im.height
        return im.resize((max(1, int(im.width * r)), H), Image.Resampling.LANCZOS)

    A, B = fit(rc), fit(bc_fair)
    W = max(A.width, B.width)

    def box(im: Image.Image) -> Image.Image:
        c = Image.new("RGB", (W, H), (235, 232, 224))
        c.paste(im, ((W - im.width) // 2, 0))
        return c

    A, B = box(A), box(B)
    gap = 28
    canvas = Image.new("RGB", (W * 2 + gap + 40, H + 56), (240, 237, 230))
    canvas.paste(A, (20, 36))
    canvas.paste(B, (20 + W + gap, 36))
    d = ImageDraw.Draw(canvas)
    d.text((20, 10), "REF toes", fill=(40, 40, 38))
    d.text((20 + W + gap, 10), "toes now", fill=(40, 40, 38))
    ART.mkdir(parents=True, exist_ok=True)
    canvas.save(ART / "cmp-part-toes.jpg", quality=92)
    bc.save(ART / "bench-tree-toes-crop.png")


if __name__ == "__main__":
    main()
