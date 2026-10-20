#!/usr/bin/env python3
"""Bake root_hero.obj — 幹下半＋趾を一体の soft-union（継ぎ目・浮き球禁止）。"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "root_hero.obj"
RES = 120
PAD = 0.05
K = 0.11
BASE_R = 0.32
TOP_Y = 0.85  # 幹下半まで含めて継ぎ目を消す


def soft_min(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def soft_max(a, b, k):
    return -soft_min(-a, -b, k)


def main():
    specs = []  # cx,cy,cz,rx,ry,rz
    # 幹円柱を縦に連続（上まで）
    n = 10
    for i in range(n):
        t = i / (n - 1)
        y = 0.08 + t * (TOP_Y - 0.08)
        # 裾だけ少し太い
        flare = 1.0 + 0.22 * max(0.0, 1.0 - y / 0.35) ** 2
        r = BASE_R * flare * (1.0 - 0.12 * t)
        specs.append((0.0, y, 0.0, r, r * 0.85, r))

    # 趾：幹裾から連続して外へ細長く
    for i in range(4):
        a = i / 4 * math.tau + 0.55
        ca, sa = math.cos(a), math.sin(a)
        # 幹側面から生え、地面へ寝る
        specs.append((ca * BASE_R * 0.35, 0.22, sa * BASE_R * 0.35, 0.16, 0.14, 0.15))
        specs.append((ca * (BASE_R + 0.06), 0.14, sa * (BASE_R + 0.06), 0.17, 0.12, 0.13))
        specs.append((ca * (BASE_R + 0.16), 0.10, sa * (BASE_R + 0.16), 0.13, 0.10, 0.11))

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

    field = soft_max(field, -Y + 0.002, 0.05)

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

    with OUT.open("w") as fo:
        fo.write("# root+lower-trunk soft-union k=%.2f top=%.2f\n" % (K, TOP_Y))
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces))


if __name__ == "__main__":
    main()
