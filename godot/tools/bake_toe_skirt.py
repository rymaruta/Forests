#!/usr/bin/env python3
"""Bake toe_skirt.obj — 部品「趾＋裾」。粘土趾の丸丘。幹柱は含めない（短い裾のみ）。"""
from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from skimage.measure import marching_cubes

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes" / "toe_skirt.obj"
RES = 140
PAD = 0.10
K_BLEND = 0.070
SEED = 5201
AO_SAMPLES = 16


def soft_min(a: np.ndarray, b: np.ndarray, k: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return (1.0 - h) * b + h * a - k * h * (1.0 - h)


def capsule_sdf(p: np.ndarray, a: np.ndarray, b: np.ndarray, ra: float, rb: float) -> np.ndarray:
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


def sphere_sdf(p: np.ndarray, c: np.ndarray, r: float) -> np.ndarray:
    return np.linalg.norm(p - c, axis=-1) - r


def build_prims():
    # 短い幹立ち上がり＋縦カプセル趾（餅裾禁止）。XZ 広がりで aspect≈3。
    prims_cap = [
        (np.array([0.0, 0.02, 0.0]), np.array([0.0, 0.32, 0.0]), 0.31, 0.20),
    ]
    # 趾もカプセル：地面→幹へ立ち上がる
    toe_caps = []
    spheres = [
        (np.array([0.0, 0.12, 0.0]), 0.26),
    ]
    n = 5
    for i in range(n):
        a = i / n * math.tau + 0.22
        rad = 0.34 + 0.035 * math.sin(i * 1.4)
        base = np.array([math.cos(a) * rad, 0.06, math.sin(a) * rad * 0.90])
        top = np.array([math.cos(a) * rad * 0.55, 0.28 + 0.02 * (i % 2), math.sin(a) * rad * 0.50])
        ra = 0.155 if i % 2 == 0 else 0.140
        rb = 0.105 if i % 2 == 0 else 0.095
        toe_caps.append((base, top, ra, rb))
        tip = base + np.array([math.cos(a) * 0.11, 0.0, math.sin(a) * 0.09])
        spheres.append((tip, 0.110 if i % 2 == 0 else 0.098))
        root = base * 0.45 + np.array([0.0, 0.10, 0.0])
        spheres.append((root, 0.125))
    return prims_cap + toe_caps, spheres


def field_at(p: np.ndarray, caps, spheres) -> np.ndarray:
    field = None
    for a, b, ra, rb in caps:
        d = capsule_sdf(p, a, b, ra, rb)
        field = d if field is None else soft_min(field, d, K_BLEND)
    for c, r in spheres:
        d = sphere_sdf(p, c, r)
        field = d if field is None else soft_min(field, d, K_BLEND)
    return field


def sdf_pt(p: np.ndarray, caps, spheres) -> float:
    field = None
    for a, b, ra, rb in caps:
        d = capsule_sdf_pt(p, a, b, ra, rb)
        if field is None:
            field = d
        else:
            h = max(0.0, min(1.0, 0.5 + 0.5 * (d - field) / K_BLEND))
            field = (1.0 - h) * d + h * field - K_BLEND * h * (1.0 - h)
    for c, r in spheres:
        d = float(np.linalg.norm(p - c) - r)
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


def bake_ao(verts, normals, caps, spheres, rng: random.Random) -> np.ndarray:
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
            for s in (0.06, 0.14, 0.26):
                if sdf_pt(p + w * s, caps, spheres) < 0.0:
                    occ = 1.0
                    break
            hit += occ
        dark = hit / AO_SAMPLES
        ao[i] = 1.0 - 0.90 * (dark ** 0.72)
    return np.clip(ao, 0.16, 1.0)


def main() -> None:
    rng = random.Random(SEED)
    caps, spheres = build_prims()
    pts = []
    for a, b, ra, rb in caps:
        pts += [a, b, a + ra, b + rb, a - ra, b - rb]
    for c, r in spheres:
        pts += [c + r, c - r, c]
    pts = np.stack(pts)
    mn = pts.min(0) - PAD
    mx = pts.max(0) + PAD
    # 地面クリップ：y>=0
    mn[1] = min(mn[1], -0.02)

    linx = np.linspace(mn[0], mx[0], RES)
    liny = np.linspace(mn[1], mx[1], RES)
    linz = np.linspace(mn[2], mx[2], RES)
    X, Y, Z = np.meshgrid(linx, liny, linz, indexing="ij")
    P = np.stack([X, Y, Z], axis=-1)
    field = field_at(P, caps, spheres)
    # 地面下を切る
    field = np.maximum(field, -Y - 0.001)

    spacing = (
        (mx[0] - mn[0]) / (RES - 1),
        (mx[1] - mn[1]) / (RES - 1),
        (mx[2] - mn[2]) / (RES - 1),
    )
    verts, faces, mc_norms, _ = marching_cubes(field, level=0.0, spacing=spacing)
    verts = verts + mn
    y0 = float(verts[:, 1].min())
    verts[:, 1] -= y0

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

    ao = bake_ao(verts, vnorm, caps, spheres, rng)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        f.write(f"# part toe_skirt toes={len(spheres)} k={K_BLEND} clay-toes+ao\n")
        for i, v in enumerate(verts):
            c = ao[i]
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f} {c:.4f} {c:.4f} {c:.4f}\n")
        for n in vnorm:
            f.write(f"vn {n[0]:.6f} {n[1]:.6f} {n[2]:.6f}\n")
        for face in faces:
            a, b, c = face[0] + 1, face[1] + 1, face[2] + 1
            f.write(f"f {a}//{a} {b}//{b} {c}//{c}\n")
    print("wrote", OUT, "verts", len(verts), "h", float(verts[:, 1].max()), "ao", float(ao.min()), float(ao.mean()))


if __name__ == "__main__":
    main()
