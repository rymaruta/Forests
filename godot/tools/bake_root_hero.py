#!/usr/bin/env python3
"""Bake root_hero.obj — 幹全体＋趾を一本の soft-union（水平継ぎ目禁止）。

縦溝はシェーダ側。ここでは形の一体感だけ作る。
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "root_hero.obj"
RES = 120
PAD = 0.05
K = 0.11
FLUTE_AMT = 0.036
BASE_R = 0.40
TOP_R = 0.18
TRUNK_H = 1.75


def soft_min(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def soft_max(a, b, k):
    return -soft_min(-a, -b, k)


def main():
    specs = []
    n = 14
    for i in range(n):
        t = i / (n - 1)
        y = 0.06 + t * (TRUNK_H - 0.06)
        flare = 1.0 + 0.30 * max(0.0, 1.0 - y / 0.40) ** 2
        r = (BASE_R * (1.0 - t) + TOP_R * t) * flare
        specs.append((0.0, y, 0.0, r, r * 0.88, r))

    for i in range(4):
        a = i / 4 * math.tau + 0.55
        ca, sa = math.cos(a), math.sin(a)
        # 低い扁平趾（膨らんだ足球禁止）
        specs.append((ca * BASE_R * 0.50, 0.14, sa * BASE_R * 0.50, 0.18, 0.10, 0.14))
        specs.append((ca * (BASE_R + 0.08), 0.10, sa * (BASE_R + 0.08), 0.14, 0.08, 0.11))
        specs.append((ca * (BASE_R + 0.16), 0.07, sa * (BASE_R + 0.16), 0.10, 0.06, 0.08))

    rs = [max(s[3], s[4], s[5]) for s in specs]
    xs = [s[0] for s in specs]
    ys = [s[1] for s in specs]
    zs = [s[2] for s in specs]
    mn = np.array([
        min(xs[i] - rs[i] for i in range(len(xs))),
        min(ys[i] - rs[i] for i in range(len(ys))),
        min(zs[i] - rs[i] for i in range(len(zs))),
    ]) - PAD
    mx = np.array([
        max(xs[i] + rs[i] for i in range(len(xs))),
        max(ys[i] + rs[i] for i in range(len(ys))),
        max(zs[i] + rs[i] for i in range(len(zs))),
    ]) + PAD

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

    # 床カットは弱く（白縁・穴禁止）。趾の底は丸く残す
    # 床の平面カットは白円盤を作るので使わない。生成後に接地シフトする。
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
    # 最下点をわずかに床上へ
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

    # 縦フルートを幾何で刻む（裾は弱め）
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
    flute_mask = np.clip((y - 0.15) / 0.35, 0.0, 1.0)
    flute = np.sin(ang * 7.0) * 0.7 + np.sin(ang * 4.0 + y * 2.0) * 0.3
    verts = verts + normals * (flute[:, None] * FLUTE_AMT * flute_mask[:, None])

    with OUT.open("w") as fo:
        fo.write("# full-trunk+toes soft-union k=%.2f h=%.2f\n" % (K, TRUNK_H))
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces))


if __name__ == "__main__":
    main()
