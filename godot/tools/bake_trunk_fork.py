#!/usr/bin/env python3
"""Bake trunk_fork.obj — 部品「幹＋クレードル枝」。滑らかな Y 字＋頂点AO。趾なし。"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "trunk_fork.obj"
RES = 160
PAD = 0.12
K_BLEND = 0.072
SEED = 4102
AO_SAMPLES = 18


def soft_min(a: np.ndarray, b: np.ndarray, k: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def capsule_sdf(p: np.ndarray, a: np.ndarray, b: np.ndarray, ra: float, rb: float) -> np.ndarray:
    """Tapered capsule SDF (broadcast over p[...,3])."""
    pa = p - a
    ba = b - a
    ba2 = float(np.dot(ba, ba)) + 1e-9
    h = np.clip(np.sum(pa * ba, axis=-1) / ba2, 0.0, 1.0)
    r = ra * (1.0 - h) + rb * h
    closest = a + ba * h[..., None]
    return np.linalg.norm(p - closest, axis=-1) - r


def capsule_sdf_pt(p: np.ndarray, a: np.ndarray, b: np.ndarray, ra: float, rb: float) -> float:
    pa = p - a
    ba = b - a
    ba2 = float(np.dot(ba, ba)) + 1e-9
    h = max(0.0, min(1.0, float(np.dot(pa, ba) / ba2)))
    r = ra * (1.0 - h) + rb * h
    return float(np.linalg.norm(p - (a + ba * h)) - r)


def build_prims():
    # 滑らかな幹柱＋立ち上がる二枝。股は丸く、枝は読める長さ。
    col_a = np.array([0.02, 0.02, 0.0])
    col_b = np.array([0.03, 1.08, 0.0])
    prims = [
        (col_a, col_b, 0.245, 0.108),
    ]
    # クレードル枝：参照の細い立ち上がり腕（全体樹シート）
    for side, yaw in ((1.0, 0.48), (-1.0, math.pi - 0.48)):
        root = np.array([0.03 + 0.015 * side, 1.02, 0.0])
        mid = np.array(
            [
                root[0] + math.cos(yaw) * 0.34,
                root[1] + 0.28,
                root[2] + math.sin(yaw) * 0.04,
            ]
        )
        tip = np.array(
            [
                root[0] + math.cos(yaw) * 0.58,
                root[1] + 0.52,
                root[2] + math.sin(yaw) * 0.06,
            ]
        )
        prims.append((root, mid, 0.100, 0.070))
        prims.append((mid, tip, 0.070, 0.040))
    # 股フィラー（浅め：枝が消えない範囲）
    crotch_a = np.array([0.03, 0.94, 0.0])
    crotch_b = np.array([0.03, 1.08, 0.0])
    prims.append((crotch_a, crotch_b, 0.125, 0.105))
    return prims


def field_at(p: np.ndarray, prims) -> np.ndarray:
    field = None
    for a, b, ra, rb in prims:
        d = capsule_sdf(p, a, b, ra, rb)
        field = d if field is None else soft_min(field, d, K_BLEND)
    return field


def sdf_pt(p: np.ndarray, prims) -> float:
    field = None
    for a, b, ra, rb in prims:
        d = capsule_sdf_pt(p, a, b, ra, rb)
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


def bake_ao(verts: np.ndarray, normals: np.ndarray, prims, rng: random.Random) -> np.ndarray:
    dirs = hemisphere_dirs(AO_SAMPLES, rng)
    ao = np.ones(len(verts), dtype=np.float64)
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
            for s in (0.08, 0.18, 0.32):
                q = p + w * s
                if sdf_pt(q, prims) < 0.0:
                    occ = 1.0
                    break
            hit += occ
        dark = hit / AO_SAMPLES
        # 股・接ぎ目を参照級に深く（p10≈45帯）
        ao[i] = 1.0 - 0.78 * (dark ** 0.82)
    return np.clip(ao, 0.28, 1.0)


def main() -> None:
    rng = random.Random(SEED)
    prims = build_prims()
    pts = []
    for a, b, ra, rb in prims:
        pts.append(a)
        pts.append(b)
        # radius extents
        for r in (ra, rb):
            pts.append(a + np.array([r, r, r]))
            pts.append(b + np.array([r, r, r]))
            pts.append(a - np.array([r, r, r]))
            pts.append(b - np.array([r, r, r]))
    pts = np.stack(pts)
    mn = pts.min(0) - PAD
    mx = pts.max(0) + PAD

    linx = np.linspace(mn[0], mx[0], RES)
    liny = np.linspace(mn[1], mx[1], RES)
    linz = np.linspace(mn[2], mx[2], RES)
    X, Y, Z = np.meshgrid(linx, liny, linz, indexing="ij")
    P = np.stack([X, Y, Z], axis=-1)
    field = field_at(P, prims)

    spacing = (
        (mx[0] - mn[0]) / (RES - 1),
        (mx[1] - mn[1]) / (RES - 1),
        (mx[2] - mn[2]) / (RES - 1),
    )
    verts, faces, mc_norms, _ = marching_cubes(field, level=0.0, spacing=spacing)
    verts = verts + mn
    y0 = float(verts[:, 1].min())
    verts[:, 1] -= y0

    # 体積勾配（外向き SDF）を頂点へサンプリング
    gx, gy, gz = np.gradient(field, spacing[0], spacing[1], spacing[2])
    idx = np.clip(
        np.round((verts + np.array([0.0, y0, 0.0]) - mn) / np.array(spacing)).astype(int),
        0,
        RES - 1,
    )
    vnorm = np.stack(
        [gx[idx[:, 0], idx[:, 1], idx[:, 2]], gy[idx[:, 0], idx[:, 1], idx[:, 2]], gz[idx[:, 0], idx[:, 1], idx[:, 2]]],
        axis=1,
    ).astype(np.float64)
    # 勾配が弱い所は marching_cubes 法線へフォールバック
    weak = np.linalg.norm(vnorm, axis=1) < 1e-6
    vnorm[weak] = mc_norms[weak]
    vnorm /= np.maximum(np.linalg.norm(vnorm, axis=1, keepdims=True), 1e-8)

    new_faces = []
    for f in faces:
        a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
        fn = np.cross(b - a, c - a)
        avg_n = vnorm[f[0]] + vnorm[f[1]] + vnorm[f[2]]
        if np.dot(fn, avg_n) < 0:
            new_faces.append([f[0], f[2], f[1]])
        else:
            new_faces.append(list(f))
    faces = np.array(new_faces)

    ao = bake_ao(verts, vnorm, prims, rng)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        f.write(f"# part trunk_fork prims={len(prims)} k={K_BLEND} y-cradle+ao\n")
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
        "h",
        float(verts[:, 1].max()),
        "ao",
        float(ao.min()),
        float(ao.mean()),
    )


if __name__ == "__main__":
    main()
