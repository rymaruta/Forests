#!/usr/bin/env python3
"""Bake root_hero.obj — 幹裾＋丸趾。趾の谷を残す（溶かしすぎ禁止）。"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "root_hero.obj"
RES = 110
PAD = 0.05
K_TRUNK = 0.11
K_TOE = 0.11  # 幹へしっかり溶かす（浮き球禁止）。趾の谷は配置で残す
BASE_R = 0.32


def soft_min(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def soft_max(a, b, k):
    return -soft_min(-a, -b, k)


def main():
    trunk_specs = []
    for i in range(7):
        y = 0.10 + i * 0.085
        r = BASE_R * (1.05 - i * 0.03)
        trunk_specs.append((0.0, y, 0.0, r, r * 0.88, r))

    toe_specs = []
    for i in range(4):
        a = i / 4 * math.tau + 0.55
        # 幹に深く埋めつつ外へ。つなぎ球で溶け合わせ
        reach = BASE_R + 0.08
        toe_specs.append((math.cos(a) * reach, 0.14, math.sin(a) * reach, 0.18, 0.15, 0.16))
        toe_specs.append((math.cos(a) * (BASE_R * 0.62), 0.20, math.sin(a) * (BASE_R * 0.62), 0.15, 0.14, 0.14))
        toe_specs.append((math.cos(a) * (BASE_R * 0.30), 0.28, math.sin(a) * (BASE_R * 0.30), 0.12, 0.12, 0.12))

    all_specs = trunk_specs + toe_specs
    rs = [max(s[3], s[4], s[5]) for s in all_specs]
    xs = [s[0] for s in all_specs]
    ys = [s[1] for s in all_specs]
    zs = [s[2] for s in all_specs]
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
    for s in trunk_specs:
        d = ell(*s)
        field = d if field is None else soft_min(field, d, K_TRUNK)

    # 各趾グループ（趾+つなぎ2）を幹へ soft-union
    for i in range(0, len(toe_specs), 3):
        toe_field = ell(*toe_specs[i])
        toe_field = soft_min(toe_field, ell(*toe_specs[i + 1]), K_TOE)
        toe_field = soft_min(toe_field, ell(*toe_specs[i + 2]), K_TOE)
        field = soft_min(field, toe_field, K_TOE)

    # 床カットは弱め（鋭い穴・白縁を出さない）。底はわずかに丸く残す
    field = soft_max(field, -Y + 0.002, 0.06)

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
        fo.write("# root soft-union toes=4 k_toe=%.2f\n" % K_TOE)
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces))


if __name__ == "__main__":
    main()
