#!/usr/bin/env python3
"""Bake canopy_hero.obj — 参照：大房＋中房の雲。細粒密集は避ける。"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "canopy_hero.obj"
BASE_R = 1.30
RES = 150
PAD = 0.13
K_BLEND = 0.12
SEED = 2901


def soft_min(a: np.ndarray, b: np.ndarray, k: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def lobe_specs():
    specs = [
        ((0.0, 0.48, 0.0), 0.46),
        ((0.0, 0.78, 0.0), 0.40),
        ((0.0, 0.30, 0.0), 0.36),
        ((0.0, 1.05, 0.0), 0.30),
    ]
    for i in range(6):
        a = i / 6 * math.tau + 0.18
        y = 0.52 + 0.06 * math.sin(i * 1.5)
        r = 0.36 if i % 2 == 0 else 0.32
        specs.append(((math.cos(a) * 0.50, y, math.sin(a) * 0.50), r))
    for i in range(5):
        a = i / 5 * math.tau + 0.48
        specs.append(((math.cos(a) * 0.30, 0.88, math.sin(a) * 0.30), 0.28))
    for i in range(3):
        a = i / 3 * math.tau + 0.70
        specs.append(((math.cos(a) * 0.18, 1.12, math.sin(a) * 0.18), 0.24))
    return specs


def main() -> None:
    rng = random.Random(SEED)
    centers = []
    radii = []
    for c, r in lobe_specs():
        centers.append(
            (
                c[0] * BASE_R + rng.uniform(-0.003, 0.003) * BASE_R,
                c[1] * BASE_R + rng.uniform(-0.002, 0.002) * BASE_R,
                c[2] * BASE_R + rng.uniform(-0.003, 0.003) * BASE_R,
            )
        )
        radii.append(r * BASE_R * rng.uniform(0.999, 1.001))

    xs = [p[0] for p in centers]
    ys = [p[1] for p in centers]
    zs = [p[2] for p in centers]
    mn = (
        np.array(
            [
                min(xs[i] - radii[i] for i in range(len(xs))),
                min(ys[i] - radii[i] for i in range(len(ys))),
                min(zs[i] - radii[i] for i in range(len(zs))),
            ]
        )
        - PAD
    )
    mx = (
        np.array(
            [
                max(xs[i] + radii[i] for i in range(len(xs))),
                max(ys[i] + radii[i] for i in range(len(ys))),
                max(zs[i] + radii[i] for i in range(len(zs))),
            ]
        )
        + PAD
    )

    linx = np.linspace(mn[0], mx[0], RES)
    liny = np.linspace(mn[1], mx[1], RES)
    linz = np.linspace(mn[2], mx[2], RES)
    X, Y, Z = np.meshgrid(linx, liny, linz, indexing="ij")
    field = None
    for (cx, cy, cz), r in zip(centers, radii):
        d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2 + (Z - cz) ** 2) - r
        field = d if field is None else soft_min(field, d, K_BLEND)

    verts, faces, _, _ = marching_cubes(
        field,
        level=0.0,
        spacing=(
            (mx[0] - mn[0]) / (RES - 1),
            (mx[1] - mn[1]) / (RES - 1),
            (mx[2] - mn[2]) / (RES - 1),
        ),
    )
    verts = verts + mn
    verts[:, 1] -= verts[:, 1].min()
    cent = verts.mean(0)
    new_faces = []
    for f in faces:
        a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
        n = np.cross(b - a, c - a)
        mid = (a + b + c) / 3
        if np.dot(n, mid - cent) < 0:
            new_faces.append([f[0], f[2], f[1]])
        else:
            new_faces.append(list(f))
    faces = np.array(new_faces)

    with OUT.open("w") as fo:
        fo.write("# soft cloud canopy lobes=%d k=%.2f\n" % (len(centers), K_BLEND))
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces), "lobes", len(centers), "k", K_BLEND)


if __name__ == "__main__":
    main()
