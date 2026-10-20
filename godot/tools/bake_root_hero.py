#!/usr/bin/env python3
"""Bake root_hero.obj — 幹＋趾を一本の soft-union（水平継ぎ目・別球・平面カット禁止）。"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "root_hero.obj"
RES = 140
PAD = 0.06
K = 0.08
FLUTE_AMT = 0.024
BASE_R = 0.40
TOP_R = 0.18
TRUNK_H = 1.84  # nature_factory trunk_h ≈ HERO_TRUNK_H * 1.05


def soft_min(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def main():
    specs = []
    # 幹を縦に積んだ楕円（なだらかテーパー）
    n = 18
    for i in range(n):
        t = i / (n - 1)
        y = 0.08 + t * (TRUNK_H - 0.08)
        # 裾は軽く広げるだけ（平スカート禁止）
        flare = 1.0 + 0.18 * max(0.0, 1.0 - y / 0.38) ** 2
        r = (BASE_R * (1.0 - t) + TOP_R * t) * flare
        ry = r * 0.55 if i < 2 else r * 0.95
        specs.append((0.0, y, 0.0, r, ry, r))

    # 丸い粘土趾（扁平板・全周スカート禁止）。やや外へ出して谷を残す
    for i in range(4):
        a = i / 4 * math.tau + 0.55
        ca, sa = math.cos(a), math.sin(a)
        # 細い接合ネック（幹→趾）
        specs.append((ca * BASE_R * 0.55, 0.18, sa * BASE_R * 0.55, 0.16, 0.14, 0.15))
        # 主趾：ほぼ球・接地・幹から明確に突き出す
        specs.append((ca * BASE_R * 1.05, 0.22, sa * BASE_R * 1.05, 0.28, 0.26, 0.27))
        # 外側の小さな丸み
        specs.append((ca * (BASE_R * 1.28), 0.12, sa * (BASE_R * 1.28), 0.14, 0.12, 0.13))

    rs = [max(s[3], s[4], s[5]) for s in specs]
    xs = [s[0] for s in specs]
    ys = [s[1] for s in specs]
    zs = [s[2] for s in specs]
    mn = np.array(
        [
            min(xs[i] - rs[i] for i in range(len(xs))),
            min(ys[i] - rs[i] for i in range(len(ys))),
            min(zs[i] - rs[i] for i in range(len(zs))),
        ]
    ) - PAD
    mx = np.array(
        [
            max(xs[i] + rs[i] for i in range(len(xs))),
            max(ys[i] + rs[i] for i in range(len(ys))),
            max(zs[i] + rs[i] for i in range(len(zs))),
        ]
    ) + PAD

    linx = np.linspace(mn[0], mx[0], RES)
    liny = np.linspace(mn[1], mx[1], RES)
    linz = np.linspace(mn[2], mx[2], RES)
    X, Y, Z = np.meshgrid(linx, liny, linz, indexing="ij")

    def ell(cx, cy, cz, rx, ry, rz):
        d = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2 + ((Z - cz) / rz) ** 2) - 1.0
        return d * min(rx, ry, rz)

    field = None
    for s in specs:
        d = ell(*s)
        field = d if field is None else soft_min(field, d, K)

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
    verts[:, 1] -= verts[:, 1].min() - 0.01
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

    # 縦フルート幾何（裾・趾は弱め）
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
    nlen = np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-12)
    normals = normals / nlen
    ang = np.arctan2(verts[:, 2], verts[:, 0])
    y = verts[:, 1]
    flute_mask = np.clip((y - 0.38) / 0.45, 0.0, 1.0)
    flute_mask = flute_mask * flute_mask * (3.0 - 2.0 * flute_mask)
    # 有機ゆらぎ：周波数と位相を高さでずらす
    flute = (
        np.sin(ang * 6.5 + y * 0.9 + np.sin(y * 2.2) * 0.4) * 0.55
        + np.sin(ang * 11.0 + y * 1.4 + 0.8) * 0.30
        + np.sin(ang * 4.0 + y * 0.5) * 0.15
    )
    verts = verts + normals * (flute[:, None] * FLUTE_AMT * flute_mask[:, None])

    with OUT.open("w") as fo:
        fo.write("# full-trunk+round-toes soft-union k=%.2f h=%.2f\n" % (K, TRUNK_H))
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces))


if __name__ == "__main__":
    main()
