#!/usr/bin/env python3
"""Bake canopy_hero.obj via 3D soft-union SDF + marching cubes.

参照: 小さめの房が密集して雲になる（巨大3球ではない）。
K_BLEND で溶かし、谷は残す。
"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "canopy_hero.obj"
BASE_R = 1.28
RES = 136
PAD = 0.14
K_BLEND = 0.11
FLOCK_DISP = 0.0  # 幾何変位は横バンドが出るので一旦オフ。質感はシェーダ側
SEED = 2901


def soft_min(a: np.ndarray, b: np.ndarray, k: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def lobe_specs():
    specs = [
        ((0.0, 0.55, 0.0), 0.42),
        ((0.0, 0.82, 0.0), 0.34),
        ((0.0, 0.28, 0.0), 0.36),
    ]
    # 中間サイズの密集房（参照の雲感）
    for i in range(8):
        a = i / 8 * math.tau + 0.15
        specs.append(
            (
                (math.cos(a) * 0.48, 0.48 + 0.06 * math.sin(i * 1.3), math.sin(a) * 0.48),
                0.30,
            )
        )
    for i in range(7):
        a = i / 7 * math.tau + 0.4
        specs.append(((math.cos(a) * 0.32, 0.78, math.sin(a) * 0.32), 0.26))
    for i in range(6):
        a = i / 6 * math.tau + 0.05
        specs.append(((math.cos(a) * 0.36, 0.18, math.sin(a) * 0.36), 0.26))
    specs.append(((0.0, 1.15, 0.0), 0.26))
    # 表層の小房（シルエットの丸み、ギザ禁止の範囲で）
    for i in range(12):
        a = i / 12 * math.tau + 0.22
        y = 0.35 + 0.55 * ((i % 5) / 4.0)
        r = 0.42 + 0.08 * math.sin(i)
        specs.append(((math.cos(a) * r * 0.55, y, math.sin(a) * r * 0.55), 0.18))
    return specs


def main() -> None:
    rng = random.Random(SEED)
    centers = []
    radii = []
    for c, r in lobe_specs():
        centers.append(
            (
                c[0] * BASE_R + rng.uniform(-0.004, 0.004) * BASE_R,
                c[1] * BASE_R + rng.uniform(-0.003, 0.003) * BASE_R,
                c[2] * BASE_R + rng.uniform(-0.004, 0.004) * BASE_R,
            )
        )
        radii.append(r * BASE_R * rng.uniform(0.998, 1.002))

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

    # 頂点法線を集計して幾何フロック変位
    normals = np.zeros_like(verts)
    for f in faces:
        a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
        n = np.cross(b - a, c - a)
        ln = np.linalg.norm(n)
        if ln > 1e-12:
            n = n / ln
            normals[f[0]] += n
            normals[f[1]] += n
            normals[f[2]] += n
    nlen = np.linalg.norm(normals, axis=1, keepdims=True)
    nlen = np.maximum(nlen, 1e-12)
    normals = normals / nlen

    # 補間付き value noise（非連続ハッシュはファセットになるので禁止）
    def hash3(ix, iy, iz):
        n = np.sin(ix * 127.1 + iy * 311.7 + iz * 74.7 + 19.19) * 43758.5453
        return n - np.floor(n)

    def vnoise(p, scale):
        sp = p * scale
        i0 = np.floor(sp)
        f = sp - i0
        f = f * f * (3.0 - 2.0 * f)
        ix, iy, iz = i0[:, 0], i0[:, 1], i0[:, 2]
        n000 = hash3(ix, iy, iz)
        n100 = hash3(ix + 1, iy, iz)
        n010 = hash3(ix, iy + 1, iz)
        n110 = hash3(ix + 1, iy + 1, iz)
        n001 = hash3(ix, iy, iz + 1)
        n101 = hash3(ix + 1, iy, iz + 1)
        n011 = hash3(ix, iy + 1, iz + 1)
        n111 = hash3(ix + 1, iy + 1, iz + 1)
        nx00 = n000 * (1 - f[:, 0]) + n100 * f[:, 0]
        nx10 = n010 * (1 - f[:, 0]) + n110 * f[:, 0]
        nx01 = n001 * (1 - f[:, 0]) + n101 * f[:, 0]
        nx11 = n011 * (1 - f[:, 0]) + n111 * f[:, 0]
        nxy0 = nx00 * (1 - f[:, 1]) + nx10 * f[:, 1]
        nxy1 = nx01 * (1 - f[:, 1]) + nx11 * f[:, 1]
        return nxy0 * (1 - f[:, 2]) + nxy1 * f[:, 2]

    f1 = vnoise(verts, 3.2)
    f2 = vnoise(verts + 1.7, 6.5)
    f3 = vnoise(verts + 3.1, 12.0)
    flock = (f1 * 0.45 + f2 * 0.35 + f3 * 0.20) - 0.5
    verts = verts + normals * (flock[:, None] * FLOCK_DISP)

    with OUT.open("w") as fo:
        fo.write("# dense MC canopy lobes=%d k=%.2f flock=%.3f\n" % (len(centers), K_BLEND, FLOCK_DISP))
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces), "lobes", len(centers), "k", K_BLEND)


if __name__ == "__main__":
    main()
