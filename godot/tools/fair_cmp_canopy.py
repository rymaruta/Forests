#!/usr/bin/env python3
"""Fair canopy AssetBench compare: match pixel density before letterbox."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REF = Path("/workspace/godot/assets/references/parts/ref-canopy.png")
BENCH = Path("/opt/cursor/artifacts/screenshots/bench-part-canopy.png")
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


def local_hp(im: Image.Image) -> float:
    a = np.asarray(im).astype(np.float32)
    h, w, _ = a.shape
    patch = a[h // 3 : 2 * h // 3, w // 3 : 2 * w // 3]
    blur = np.asarray(
        Image.fromarray(patch.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))
    ).astype(np.float32)
    return float((patch - blur).std())


def hue(im: Image.Image) -> float:
    a = np.asarray(im).astype(np.float32)
    c = np.stack([a[4, 4], a[4, -4], a[-4, 4], a[-4, -4]]).mean(0)
    pix = a[np.abs(a - c).sum(2) > 28].mean(0)
    return float((pix[0] - pix[2]) / (pix[1] + 1e-3))


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
    )


def main() -> None:
    ref = Image.open(REF).convert("RGB")
    bench = Image.open(BENCH).convert("RGB")
    rc = subject_crop(ref, 8)
    bc = subject_crop(bench, 18)
    # Match density: NOW down to REF height before display upscale
    bc_fair = bc.resize(
        (max(1, int(bc.width * rc.height / bc.height)), rc.height),
        Image.Resampling.LANCZOS,
    )
    print(
        "hp_std",
        round(local_hp(rc), 2),
        round(local_hp(bc_fair), 2),
        "aspect",
        round(rc.width / rc.height, 2),
        round(bc_fair.width / bc_fair.height, 2),
        "rb/g",
        round(hue(rc), 3),
        round(hue(bc_fair), 3),
    )
    H = max(rc.height * 2, 340)

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
    d.text((20, 10), "REF canopy", fill=(40, 40, 38))
    d.text((20 + W + gap, 10), "canopy now", fill=(40, 40, 38))
    ART.mkdir(parents=True, exist_ok=True)
    canvas.save(ART / "cmp-part-canopy.jpg", quality=92)
    canvas.save(ART / "walkthrough-cmp-part-canopy.jpg", quality=92)
    bench.save(ART / "walkthrough-part-canopy.png")
    bc.save(ART / "bench-tree-canopy-crop.png")
    stats(rc, "REF")
    stats(bc_fair, "NOW")


if __name__ == "__main__":
    main()
