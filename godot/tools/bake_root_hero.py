#!/usr/bin/env python3
"""Bake root_hero.obj — 幹＋粘土趾を一本の soft-union。

比率は nature_factory ヒーロー定数に合わせる。
球チェーン／別体貼り付け／平スカート禁止。
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "root_hero.obj"
RES = 168
PAD = 0.08
K = 0.13
FLUTE_AMT = 0.028
# nature_factory HERO_* と同期
BASE_R = 0.38
TOP_R = 0.16
TRUNK_H = 1.78 * 1.05
TOE_N = 4
TOE_PHASE = 0.38


def soft_min(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def main():
    # ("aa", cx,cy,cz,rx,ry,rz) or ("yaw", cx,cy,cz,rx,ry,rz,yaw)
    oriented = []
    n = 28
    for i in range(n):
        t = i / (n - 1)
        y = 0.05 + t * (TRUNK_H - 0.05)
        flare = 1.0 + 0.18 * max(0.0, 1.0 - y / 0.50) ** 2
        r = (BASE_R * (1.0 - t) + TOP_R * t) * flare
        # 接地付近は縦に潰して床に吸い付く
        ry = r * (0.55 if i < 2 else 0.90)
        oriented.append(("aa", 0.0, y, 0.0, r, ry, r))

    for i in range(TOE_N):
        a = i / TOE_N * math.tau + TOE_PHASE
        ca, sa = math.cos(a), math.sin(a)
        # 幹付け根の丘
        oriented.append(
            ("aa", ca * BASE_R * 0.42, 0.28, sa * BASE_R * 0.42, 0.20, 0.18, 0.20)
        )
        # 主マウンド：外向きに長く、上に丸い腹
        oriented.append(
            (
                "yaw",
                ca * BASE_R * 1.05,
                0.16,
                sa * BASE_R * 1.05,
                0.34,
                0.135,
                0.17,
                a,
            )
        )
        # 先端の丸いパッド（接地）
        oriented.append(
            (
                "yaw",
                ca * BASE_R * 1.55,
                0.09,
                sa * BASE_R * 1.55,
                0.16,
                0.09,
                0.12,
                a,
            )
        )

    rs = [max(o[4], o[5], o[6]) for o in oriented]
    xs = [o[1] for o in oriented]
    ys = [o[2] for o in oriented]
    zs = [o[3] for o in oriented]
    mn = (
        np.array(
            [
                min(xs[i] - rs[i] for i in range(len(xs))),
                min(ys[i] - rs[i] for i in range(len(ys))),
                min(zs[i] - rs[i] for i in range(len(zs))),
            ]
        )
        - PAD
    )
    mx = (
        np.array(
            [
                max(xs[i] + rs[i] for i in range(len(xs))),
                max(ys[i] + rs[i] for i in range(len(ys))),
                max(zs[i] + rs[i] for i in range(len(zs))),
            ]
        )
        + PAD
    )

    linx = np.linspace(mn[0], mx[0], RES)
    liny = np.linspace(mn[1], mx[1], RES)
    linz = np.linspace(mn[2], mx[2], RES)
    X, Y, Z = np.meshgrid(linx, liny, linz, indexing="ij")

    def ell_aa(cx, cy, cz, rx, ry, rz):
        d = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2 + ((Z - cz) / rz) ** 2) - 1.0
        return d * min(rx, ry, rz)

    def ell_yaw(cx, cy, cz, rx, ry, rz, yaw):
        dx = X - cx
        dy = Y - cy
        dz = Z - cz
        c, s = math.cos(-yaw), math.sin(-yaw)
        lx = c * dx + s * dz
        lz = -s * dx + c * dz
        d = np.sqrt((lx / rx) ** 2 + (dy / ry) ** 2 + (lz / rz) ** 2) - 1.0
        return d * min(rx, ry, rz)

    field = None
    for o in oriented:
        if o[0] == "aa":
            d = ell_aa(o[1], o[2], o[3], o[4], o[5], o[6])
        else:
            d = ell_yaw(o[1], o[2], o[3], o[4], o[5], o[6], o[7])
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
        nrm = np.cross(b - a, c - a)
        mid = (a + b + c) / 3
        if np.dot(nrm, mid - cent) < 0:
            new_faces.append([f[0], f[2], f[1]])
        else:
            new_faces.append(list(f))
    faces = np.array(new_faces)

    normals = np.zeros_like(verts)
    for f in faces:
        a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
        nrm = np.cross(b - a, c - a)
        ln = np.linalg.norm(nrm)
        if ln > 1e-12:
            nrm = nrm / ln
            normals[f[0]] += nrm
            normals[f[1]] += nrm
            normals[f[2]] += nrm
    nlen = np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-12)
    normals = normals / nlen
    ang = np.arctan2(verts[:, 2], verts[:, 0])
    y = verts[:, 1]
    # 裾は溝を弱め、幹中腹から読める太い彫刻
    flute_mask = np.clip((y - 0.38) / 0.55, 0.0, 1.0)
    flute_mask = flute_mask * flute_mask * (3.0 - 2.0 * flute_mask)
    warp = np.sin(y * 2.1) * 0.40 + np.sin(ang * 1.7 + y * 0.8) * 0.30
    # 約6本の太い溝
    flute = (
        np.sin(ang * 3.0 + y * 0.55 + warp) * 0.72
        + np.sin(ang * 6.0 + y * 1.1 + 0.8) * 0.18
        + np.sin(ang * 1.5 + y * 0.3) * 0.10
    )
    verts = verts + normals * (flute[:, None] * FLUTE_AMT * flute_mask[:, None])

    with OUT.open("w") as fo:
        fo.write(
            "# soft-union trunk+clay toes k=%.2f h=%.2f base_r=%.2f\n"
            % (K, TRUNK_H, BASE_R)
        )
        for v in verts:
            fo.write("v %.5f %.5f %.5f\n" % tuple(v))
        for f in faces:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("wrote", OUT, "verts", len(verts), "faces", len(faces))


if __name__ == "__main__":
    main()
