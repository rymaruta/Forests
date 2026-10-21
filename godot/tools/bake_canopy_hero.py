#!/usr/bin/env python3
"""Bake canopy_hero.obj — 部品「冠」専用。大きな丸丘の柔らかい積雲＋頂点AO。"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "canopy_hero.obj"
BASE_R = 1.28
RES = 176
PAD = 0.16
# 中房を残しつつ縫い目を溶かす
K_BLEND = 0.058
SEED = 3402
AO_SAMPLES = 20


def soft_min(a: np.ndarray, b: np.ndarray, k: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def lobe_specs():
    # 参照冠: 大房芯＋中房リング。細粒ポップコーン禁止、粘土大球も禁止。
    specs = [
        ((0.00, 0.30, 0.00), 0.42),
        ((0.02, 0.50, -0.02), 0.36),
        ((-0.02, 0.68, 0.02), 0.30),
        ((0.00, 0.84, 0.00), 0.22),
        ((0.04, 0.14, 0.02), 0.30),
    ]
    for i in range(9):
        a = i / 9 * math.tau + 0.10
        y = 0.28 + 0.08 * math.sin(i * 1.6)
        rad = 0.36 + 0.05 * math.cos(i * 1.2)
        r = 0.28 if i % 2 == 0 else 0.24
        specs.append(((math.cos(a) * rad, y, math.sin(a) * rad), r))
    for i in range(8):
        a = i / 8 * math.tau + 0.40
        y = 0.48 + 0.07 * math.cos(i * 1.3)
        rad = 0.28 + 0.04 * math.sin(i * 1.1)
        specs.append(((math.cos(a) * rad, y, math.sin(a) * rad), 0.22))
    for i in range(7):
        a = i / 7 * math.tau + 0.22
        y = 0.64 + 0.05 * math.sin(i * 1.8)
        rad = 0.18 + 0.05 * ((i * 3) % 5) / 5.0
        specs.append(((math.cos(a) * rad, y, math.sin(a) * rad), 0.18))
    for i in range(8):
        a = i / 8 * math.tau + 0.28
        specs.append(((math.cos(a) * 0.24, 0.11, math.sin(a) * 0.24), 0.18))
    return specs


def sdf_at(p: np.ndarray, centers: list, radii: list) -> float:
    field = None
    for (cx, cy, cz), r in zip(centers, radii):
        d = float(np.linalg.norm(p - np.array([cx, cy, cz], dtype=np.float64)) - r)
        if field is None:
            field = d
        else:
            h = max(0.0, min(1.0, 0.5 + 0.5 * (d - field) / K_BLEND))
            field = (1.0 - h) * d + h * field - K_BLEND * h * (1.0 - h)
    return float(field)


def hemisphere_dirs(n: int, rng: random.Random) -> list[np.ndarray]:
    dirs = []
    for _ in range(n):
        u = rng.random()
        v = rng.random()
        z = u
        r = math.sqrt(max(0.0, 1.0 - z * z))
        th = 2.0 * math.pi * v
        dirs.append(np.array([r * math.cos(th), z, r * math.sin(th)], dtype=np.float64))
    return dirs


def bake_ao(verts: np.ndarray, normals: np.ndarray, centers, radii, rng: random.Random) -> np.ndarray:
    dirs = hemisphere_dirs(AO_SAMPLES, rng)
    ao = np.ones(len(verts), dtype=np.float64)
    radius = BASE_R * 0.55
    for i in range(len(verts)):
        p = verts[i]
        n = normals[i]
        nn = float(np.linalg.norm(n))
        if nn < 1e-8:
            continue
        n = n / nn
        up = np.array([0.0, 1.0, 0.0]) if abs(n[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
        t = np.cross(up, n)
        t /= max(1e-8, np.linalg.norm(t))
        b = np.cross(n, t)
        hit = 0.0
        for d in dirs:
            w = t * d[0] + n * d[1] + b * d[2]
            occ = 0.0
            for s in (0.10, 0.22, 0.38):
                q = p + w * (s * radius)
                if sdf_at(q, centers, radii) < 0.0:
                    occ = 1.0
                    break
            hit += occ
        dark = hit / AO_SAMPLES
        # 広く深い谷影（細かい割れ禁止）
        ao[i] = 1.0 - 0.66 * (dark ** 0.88)
    return np.clip(ao, 0.40, 1.0)


def main() -> None:
    rng = random.Random(SEED)
    centers = []
    radii = []
    for c, r in lobe_specs():
        centers.append(
            (
                c[0] * BASE_R + rng.uniform(-0.002, 0.002) * BASE_R,
                c[1] * BASE_R + rng.uniform(-0.002, 0.002) * BASE_R,
                c[2] * BASE_R + rng.uniform(-0.002, 0.002) * BASE_R,
            )
        )
        radii.append(r * BASE_R * rng.uniform(0.999, 1.001))

    xs = [p[0] for p in centers]
    ys = [p[1] for p in centers]
    zs = [p[2] for p in centers]
    mn = np.array(
        [
            min(xs[i] - radii[i] for i in range(len(xs))),
            min(ys[i] - radii[i] for i in range(len(ys))),
            min(zs[i] - radii[i] for i in range(len(zs))),
        ]
    ) - PAD
    mx = np.array(
        [
            max(xs[i] + radii[i] for i in range(len(xs))),
            max(ys[i] + radii[i] for i in range(len(ys))),
            max(zs[i] + radii[i] for i in range(len(zs))),
        ]
    ) + PAD

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

    vnorm = np.zeros_like(verts)
    for f in faces:
        a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
        n = np.cross(b - a, c - a)
        vnorm[f[0]] += n
        vnorm[f[1]] += n
        vnorm[f[2]] += n
    lens = np.linalg.norm(vnorm, axis=1, keepdims=True)
    lens = np.maximum(lens, 1e-8)
    vnorm = vnorm / lens

    ao = bake_ao(verts, vnorm, centers, radii, rng)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        f.write(f"# part canopy lobes={len(centers)} k={K_BLEND} large-soft-mounds+ao\n")
        for i, v in enumerate(verts):
            c = ao[i]
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f} {c:.4f} {c:.4f} {c:.4f}\n")
        for n in vnorm:
            f.write(f"vn {n[0]:.6f} {n[1]:.6f} {n[2]:.6f}\n")
        for face in faces:
            a, b, c = face[0] + 1, face[1] + 1, face[2] + 1
            f.write(f"f {a}//{a} {b}//{b} {c}//{c}\n")
    print(
        "wrote",
        OUT,
        "verts",
        len(verts),
        "lobes",
        len(centers),
        "h",
        float(verts[:, 1].max()),
        "ao",
        float(ao.min()),
        float(ao.mean()),
    )


if __name__ == "__main__":
    main()
