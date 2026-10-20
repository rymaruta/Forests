extends RefCounted
class_name CraftMeshes
## Forests 手組みメッシュ。妥協せず一から形をつくる。


static func _noise3(p: Vector3, seed: float = 0.0) -> float:
	var n := sin(p.x * 1.7 + seed) * cos(p.z * 1.3 + seed * 1.1)
	n += 0.5 * sin(p.x * 3.1 + p.y * 2.2 + seed * 2.0)
	n += 0.25 * sin(p.z * 5.2 + p.x * 4.1 + seed)
	n += 0.12 * sin(p.y * 7.3 + p.x * 2.1 + seed * 0.7)
	return n * 0.5 + 0.5


static func uv_sphere(radius: float, rings: int, segments: int, displace: float = 0.0, seed: float = 1.0, squash_y: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		var y0 := cos(PI * v0) * squash_y
		var y1 := cos(PI * v1) * squash_y
		var r0 := sin(PI * v0)
		var r1 := sin(PI * v1)
		for j in segments:
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			var a0 := u0 * TAU
			var a1 := u1 * TAU
			var pts := [
				Vector3(r0 * cos(a0), y0, r0 * sin(a0)),
				Vector3(r0 * cos(a1), y0, r0 * sin(a1)),
				Vector3(r1 * cos(a0), y1, r1 * sin(a0)),
				Vector3(r1 * cos(a1), y1, r1 * sin(a1)),
			]
			if displace > 0.0:
				for k in 4:
					var p: Vector3 = pts[k]
					pts[k] = p * (1.0 + (_noise3(p, seed) - 0.5) * displace)
			_tri_uv(st, pts[0] * radius, pts[1] * radius, pts[2] * radius, Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1))
			_tri_uv(st, pts[1] * radius, pts[3] * radius, pts[2] * radius, Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
	st.generate_normals()
	return st.commit()


static func trunk(height: float, bottom_r: float, top_r: float, segments: int = 12, lean: float = 0.0, bark_ripple: float = 0.04, cap_top: bool = true, root_toes: int = 0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 14
	for i in rings:
		var t0 := float(i) / float(rings)
		var t1 := float(i + 1) / float(rings)
		var y0 := t0 * height
		var y1 := t1 * height
		var r0 := lerpf(bottom_r, top_r, t0 * t0 * 0.35 + t0 * 0.65)
		var r1 := lerpf(bottom_r, top_r, t1 * t1 * 0.35 + t1 * 0.65)
		# root flare（参照：丸く厚い裾。星型ブースト無しでも成立）
		if t0 < 0.28:
			var ft0: float = 1.0 - t0 / 0.28
			r0 *= 1.0 + 0.62 * ft0 * ft0
		if t1 < 0.28:
			var ft1: float = 1.0 - t1 / 0.28
			r1 *= 1.0 + 0.62 * ft1 * ft1
		var lean0 := lean * t0 * t0
		var lean1 := lean * t1 * t1
		for j in segments:
			var a0 := float(j) / float(segments) * TAU
			var a1 := float(j + 1) / float(segments) * TAU
			var toe0 := _root_toe_boost(a0, t0, root_toes)
			var toe1 := _root_toe_boost(a1, t0, root_toes)
			var toe2 := _root_toe_boost(a0, t1, root_toes)
			var toe3 := _root_toe_boost(a1, t1, root_toes)
			# 縦フルート（正面からも溝が読める）
			var ripple0 := 1.0 + bark_ripple * (0.65 * sin(a0 * 8.0) + 0.35 * sin(a0 * 5.0 + t0 * 3.0))
			var ripple1 := 1.0 + bark_ripple * (0.65 * sin(a1 * 8.0) + 0.35 * sin(a1 * 5.0 + t0 * 3.0))
			var ripple2 := 1.0 + bark_ripple * (0.65 * sin(a0 * 8.0) + 0.35 * sin(a0 * 5.0 + t1 * 3.0))
			var ripple3 := 1.0 + bark_ripple * (0.65 * sin(a1 * 8.0) + 0.35 * sin(a1 * 5.0 + t1 * 3.0))
			var p00 := Vector3(cos(a0) * r0 * ripple0 * toe0 + lean0, y0, sin(a0) * r0 * ripple0 * toe0)
			var p10 := Vector3(cos(a1) * r0 * ripple1 * toe1 + lean0, y0, sin(a1) * r0 * ripple1 * toe1)
			var p01 := Vector3(cos(a0) * r1 * ripple2 * toe2 + lean1, y1, sin(a0) * r1 * ripple2 * toe2)
			var p11 := Vector3(cos(a1) * r1 * ripple3 * toe3 + lean1, y1, sin(a1) * r1 * ripple3 * toe3)
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			_tri_uv(st, p00, p10, p01, Vector2(u0, t0), Vector2(u1, t0), Vector2(u0, t1))
			_tri_uv(st, p10, p11, p01, Vector2(u1, t0), Vector2(u1, t1), Vector2(u0, t1))
	# 底を閉じて中空見えを防ぐ（toe外形に追従）
	var bot_c := Vector3(0, 0.001, 0)
	for j in segments:
		var a0 := float(j) / float(segments) * TAU
		var a1 := float(j + 1) / float(segments) * TAU
		var br0 := bottom_r * 1.72 * _root_toe_boost(a0, 0.0, root_toes)
		var br1 := bottom_r * 1.72 * _root_toe_boost(a1, 0.0, root_toes)
		var p0 := Vector3(cos(a0) * br0, 0.001, sin(a0) * br0)
		var p1 := Vector3(cos(a1) * br1, 0.001, sin(a1) * br1)
		_tri(st, bot_c, p1, p0)
	if cap_top:
		var top_lean := lean
		var top_c := Vector3(top_lean, height, 0)
		for j in segments:
			var a0 := float(j) / float(segments) * TAU
			var a1 := float(j + 1) / float(segments) * TAU
			var p0 := Vector3(cos(a0) * top_r + top_lean, height, sin(a0) * top_r)
			var p1 := Vector3(cos(a1) * top_r + top_lean, height, sin(a1) * top_r)
			_tri(st, top_c, p0, p1)
	st.generate_normals()
	return st.commit()


static func _root_toe_boost(angle: float, t: float, toes: int) -> float:
	## 幹フレアに丸い指を彫る（角ばった星型禁止）
	if toes <= 0 or t > 0.32:
		return 1.0
	var fall := 1.0 - t / 0.32
	fall = fall * fall * (3.0 - 2.0 * fall)
	var best := 0.0
	for i in toes:
		var center := float(i) / float(toes) * TAU + 0.35
		var d: float = absf(atan2(sin(angle - center), cos(angle - center)))
		var lobe: float = clampf(1.0 - d / 0.85, 0.0, 1.0)
		lobe = lobe * lobe * (3.0 - 2.0 * lobe)
		best = maxf(best, lobe)
	return 1.0 + 0.48 * best * fall


static func branch(length: float, start_r: float, end_r: float, segments: int = 6, bend: float = 0.2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 5
	for i in rings:
		var t0 := float(i) / float(rings)
		var t1 := float(i + 1) / float(rings)
		var y0 := t0 * length
		var y1 := t1 * length
		var r0 := lerpf(start_r, end_r, t0)
		var r1 := lerpf(start_r, end_r, t1)
		var off0 := bend * t0 * t0
		var off1 := bend * t1 * t1
		for j in segments:
			var a0 := float(j) / float(segments) * TAU
			var a1 := float(j + 1) / float(segments) * TAU
			var p00 := Vector3(cos(a0) * r0 + off0, y0, sin(a0) * r0)
			var p10 := Vector3(cos(a1) * r0 + off0, y0, sin(a1) * r0)
			var p01 := Vector3(cos(a0) * r1 + off1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1 + off1, y1, sin(a1) * r1)
			_tri(st, p00, p10, p01)
			_tri(st, p10, p11, p01)
	st.generate_normals()
	return st.commit()


static func canopy_volume(rng: RandomNumberGenerator, base_r: float = 1.15) -> ArrayMesh:
	## 雲形のひと続きシルエット。球の房ではなく、スカラップ縁の単一体。
	return canopy_cloud(rng, base_r)


static func canopy_cloud(rng: RandomNumberGenerator, base_r: float = 1.15) -> ArrayMesh:
	## 参照のふわっと雲冠本体。高分割シェルでシルエットの一体感を保つ。
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lobes := rng.randi_range(5, 7)
	var lobe_amp := rng.randf_range(0.22, 0.32)
	var phase := rng.randf() * TAU
	var squash := rng.randf_range(0.88, 0.98)
	var rings := 20
	var segs := 40
	for i in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		for j in segs:
			var u0 := float(j) / float(segs)
			var u1 := float(j + 1) / float(segs)
			var p0 := _cloud_p(v0, u0, base_r, squash, lobes, lobe_amp, phase)
			var p1 := _cloud_p(v0, u1, base_r, squash, lobes, lobe_amp, phase)
			var p2 := _cloud_p(v1, u0, base_r, squash, lobes, lobe_amp, phase)
			var p3 := _cloud_p(v1, u1, base_r, squash, lobes, lobe_amp, phase)
			_tri_uv(st, p0, p1, p2, Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1))
			_tri_uv(st, p1, p3, p2, Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
	st.generate_normals()
	return st.commit()


static func weld_smooth(mesh: Mesh, epsilon: float = 0.0008) -> ArrayMesh:
	## CSG等の面割れ頂点を溶接してスムーズノーマルを張る
	if mesh.get_surface_count() < 1:
		return mesh as ArrayMesh if mesh is ArrayMesh else ArrayMesh.new()
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var old_idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if old_idx.is_empty():
		old_idx.resize(verts.size())
		for i in verts.size():
			old_idx[i] = i
	# 空間量子化で溶接
	var key_to_new: Dictionary = {}
	var new_verts: PackedVector3Array = PackedVector3Array()
	var remap: PackedInt32Array = PackedInt32Array()
	remap.resize(verts.size())
	var inv := 1.0 / epsilon
	for i in verts.size():
		var p: Vector3 = verts[i]
		var key := Vector3i(int(round(p.x * inv)), int(round(p.y * inv)), int(round(p.z * inv)))
		if key_to_new.has(key):
			remap[i] = int(key_to_new[key])
		else:
			var ni := new_verts.size()
			key_to_new[key] = ni
			new_verts.append(p)
			remap[i] = ni
	var new_idx := PackedInt32Array()
	new_idx.resize(old_idx.size())
	for i in old_idx.size():
		new_idx[i] = remap[old_idx[i]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, new_idx.size(), 3):
		if i + 2 >= new_idx.size():
			break
		var a: Vector3 = new_verts[new_idx[i]]
		var b: Vector3 = new_verts[new_idx[i + 1]]
		var c: Vector3 = new_verts[new_idx[i + 2]]
		# 簡易球面UV
		st.set_uv(_dir_uv(a))
		st.add_vertex(a)
		st.set_uv(_dir_uv(b))
		st.add_vertex(b)
		st.set_uv(_dir_uv(c))
		st.add_vertex(c)
	st.index()
	st.generate_normals()
	return st.commit()


static func _dir_uv(p: Vector3) -> Vector2:
	var n := p.normalized() if p.length_squared() > 0.0001 else Vector3.UP
	var u := atan2(n.z, n.x) / TAU + 0.5
	var v := 0.5 - asin(clampf(n.y, -1.0, 1.0)) / PI
	return Vector2(u, v)


static func canopy_soft_union(rng: RandomNumberGenerator, base_r: float = 1.15) -> ArrayMesh:
	## 参照雲冠：外周に並ぶ中房のソフトユニオン（溶けすぎずスカラップが残る）。
	## 中心1巨大球は禁止。半径は近い房同士で重なるが、外縁のコブが読める配置。
	var centers: Array[Vector3] = []
	var radii: Array[float] = []
	var specs: Array = _hero_canopy_lobe_specs()
	var centroid := Vector3.ZERO
	for s in specs:
		var c: Vector3 = (s["c"] as Vector3) * base_r
		c += Vector3(rng.randf_range(-0.012, 0.012), rng.randf_range(-0.01, 0.01), rng.randf_range(-0.012, 0.012)) * base_r
		var rr: float = float(s["r"]) * base_r * rng.randf_range(0.99, 1.01)
		centers.append(c)
		radii.append(rr)
		centroid += c
	centroid /= float(centers.size())
	for i in centers.size():
		centers[i] = centers[i] - centroid

	var bound := 0.0
	for i in centers.size():
		bound = maxf(bound, centers[i].length() + radii[i])
	bound *= 1.08

	var rings := 56
	var segs := 84
	var grid: Array = []
	grid.resize((rings + 1) * (segs + 1))
	for i in rings + 1:
		for j in segs + 1:
			var v := float(i) / float(rings)
			var u := float(j) / float(segs)
			grid[i * (segs + 1) + j] = _soft_union_p(v, u, centers, radii, bound) + centroid

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		for j in segs:
			var i00 := i * (segs + 1) + j
			var i10 := i * (segs + 1) + j + 1
			var i01 := (i + 1) * (segs + 1) + j
			var i11 := (i + 1) * (segs + 1) + j + 1
			var p00: Vector3 = grid[i00]
			var p10: Vector3 = grid[i10]
			var p01: Vector3 = grid[i01]
			var p11: Vector3 = grid[i11]
			var u0 := float(j) / float(segs)
			var u1 := float(j + 1) / float(segs)
			var v0 := float(i) / float(rings)
			var v1 := float(i + 1) / float(rings)
			_tri_uv(st, p00, p01, p10, Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v0))
			_tri_uv(st, p10, p01, p11, Vector2(u1, v0), Vector2(u0, v1), Vector2(u1, v1))
	st.generate_normals()
	return st.commit()


static func _hero_canopy_lobe_specs() -> Array:
	## 参照：重なりの大きい中房クラスタ。切れ目より一体の雲。
	var specs: Array = []
	specs.append({"c": Vector3(0.0, 0.55, 0.0), "r": 0.58})
	for i in 6:
		var a := float(i) / 6.0 * TAU + 0.2
		specs.append({
			"c": Vector3(cos(a) * 0.52, 0.48 + 0.05 * sin(float(i) * 1.3), sin(a) * 0.52),
			"r": 0.46 if i % 2 == 0 else 0.42,
		})
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.6
		specs.append({
			"c": Vector3(cos(a) * 0.32, 0.95, sin(a) * 0.32),
			"r": 0.38,
		})
	specs.append({"c": Vector3(0.0, 1.18, 0.0), "r": 0.34})
	# 下縁を埋めて幹差し込み部の穴を防ぐ
	specs.append({"c": Vector3(0.0, 0.18, 0.0), "r": 0.48})
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.4
		specs.append({
			"c": Vector3(cos(a) * 0.38, 0.22, sin(a) * 0.38),
			"r": 0.36,
		})
	return specs


static func _soft_union_p(v: float, u: float, centers: Array[Vector3], radii: Array[float], bound: float) -> Vector3:
	var yaw := u * TAU
	var elev := (0.5 - v) * PI
	var dir := Vector3(cos(elev) * cos(yaw), sin(elev), cos(elev) * sin(yaw)).normalized()
	# やや溶かして粘土つなぎ（高K＋高周波ノイズは切れ目の元）
	const K := 12.0
	var acc := 0.0
	var wsum := 0.0
	for i in centers.size():
		var ri := _ray_sphere_far(dir, centers[i], radii[i])
		if ri <= 0.0:
			continue
		var w: float = exp(K * ri / bound)
		acc += w * ri
		wsum += w
	var r_out: float = (acc / wsum) if wsum > 0.0 else bound * 0.2
	r_out = clampf(r_out, 0.05, bound)
	var p := dir * r_out
	# ごく弱い低周波だけ（折りたたみ禁止）
	p += dir * (_noise3(p * 1.6, 5.1) - 0.5) * 0.018 * bound
	return p


static func _ray_sphere_far(dir: Vector3, center: Vector3, radius: float) -> float:
	var b: float = dir.dot(center)
	var c: float = center.dot(center) - radius * radius
	var disc: float = b * b - c
	if disc < 0.0:
		return 0.0
	return b + sqrt(disc)


static func _cloud_p(v: float, u: float, base_r: float, squash: float, lobes: int, lobe_amp: float, phase: float) -> Vector3:
	var yaw := u * TAU
	var elev := (v - 0.5) * 2.0
	var lat_r: float = pow(max(1.0 - elev * elev, 0.0), 0.4)
	# 柔らかいコブ（abs(sin)で丸い隆起）
	var bump: float = abs(sin(0.5 * float(lobes) * yaw + phase))
	bump = bump * bump # なだらかに
	var scallop: float = 1.0 + lobe_amp * bump * smoothstep(0.12, 0.88, lat_r)
	scallop += lobe_amp * 0.25 * abs(sin(float(lobes + 2) * yaw * 0.5 + phase * 1.3)) * lat_r
	# 高さ方向にもわずかなコブ（頂を雲らしく）
	var y_bump: float = 0.1 * bump * lat_r
	var tuck: float = 1.0
	if elev < -0.08:
		tuck = lerpf(0.3, 1.0, clamp((elev + 1.0) / 0.92, 0.0, 1.0))
	var r: float = base_r * lat_r * scallop * tuck
	var y: float = elev * base_r * squash * 0.72 + base_r * 0.42 + y_bump * base_r
	return Vector3(cos(yaw) * r, y, sin(yaw) * r)


static func leaf_cards(rng: RandomNumberGenerator, count: int, span: float) -> ArrayMesh:
	## 樹冠縁の葉カード（薄い黒線にならないよう厚め）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var p := Vector3(
			rng.randf_range(-span, span),
			rng.randf_range(0.05, span * 1.05),
			rng.randf_range(-span, span)
		)
		var s := rng.randf_range(0.2, 0.36)
		var yaw := rng.randf() * TAU
		var pitch := rng.randf_range(-0.45, 0.45)
		_leaf_quad(st, p, s, yaw, pitch, rng.randf())
	st.generate_normals()
	return st.commit()


static func pine_canopy(layers: int, base_r: float, height: float) -> ArrayMesh:
	## 垂れ気味の段。各段はスカラップ縁の傘状シェル。
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in layers:
		var t := float(i) / float(max(layers - 1, 1))
		var y := 0.2 + t * height * 0.88
		var r := base_r * (1.0 - t * 0.75) * (0.92 + 0.08 * sin(i * 1.7))
		_append_pine_skirt(st, y, r, 0.22 + (1.0 - t) * 0.18, 16, 5 + i % 2)
	# tip
	_append_displaced_sphere(st, Vector3(0, height * 0.98, 0), base_r * 0.18, 1.15, 8, 10, 0.12, 200.0)
	st.generate_normals()
	return st.commit()


static func _append_pine_skirt(st: SurfaceTool, y: float, radius: float, depth: float, segs: int, lobes: int) -> void:
	var tip := Vector3(0, y + depth * 0.85, 0)
	for j in segs:
		var a0 := float(j) / float(segs) * TAU
		var a1 := float(j + 1) / float(segs) * TAU
		var u0 := float(j) / float(segs)
		var u1 := float(j + 1) / float(segs)
		var jag0 := 1.0 + 0.12 * sin(a0 * float(lobes))
		var jag1 := 1.0 + 0.12 * sin(a1 * float(lobes))
		var p0 := Vector3(cos(a0) * radius * jag0, y - depth * 0.15, sin(a0) * radius * jag0)
		var p1 := Vector3(cos(a1) * radius * jag1, y - depth * 0.15, sin(a1) * radius * jag1)
		_tri_uv(st, tip, p0, p1, Vector2(0.5, 0.0), Vector2(u0, 1.0), Vector2(u1, 1.0))
		var mid := Vector3(0, y - depth * 0.05, 0)
		_tri_uv(st, mid, p1, p0, Vector2(0.5, 0.5), Vector2(u1, 1.0), Vector2(u0, 1.0))


static func flower_petals(petal_count: int, size: float = 0.16) -> ArrayMesh:
	## 薄い三角ではなく、厚みのある花びら房（黒線ノイズ防止）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in petal_count:
		var ang := float(i) / float(petal_count) * TAU
		var c := Vector3(cos(ang) * size * 0.45, size * 0.12, sin(ang) * size * 0.45)
		_append_displaced_sphere(st, c, size * 0.55, 0.42, 6, 8, 0.12, 5.0 + float(i) * 3.0)
	st.generate_normals()
	return st.commit()


static func flower_leaf(size: float = 0.1, seed: float = 1.0) -> ArrayMesh:
	## 茎につく厚めの葉
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_displaced_sphere(st, Vector3(0, 0, 0), size, 0.35, 5, 7, 0.1, seed)
	st.generate_normals()
	return st.commit()


static func roof_shingles(width: float, depth: float, rows: int = 5) -> ArrayMesh:
	## 片流れ屋根用の重ね板（厚みのある瓦）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var row_d := depth / float(rows)
	for r in rows:
		var z0 := -depth * 0.5 + r * row_d
		var z1 := z0 + row_d * 1.08
		var y0 := float(r) * 0.035
		var y1 := y0 + 0.05
		var x0 := -width * 0.5
		var x1 := width * 0.5
		# top
		_tri(st, Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z1))
		_tri(st, Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1))
		# front lip
		_tri(st, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x0, y1, z1))
		_tri(st, Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1))
	st.generate_normals()
	return st.commit()


static func grass_clump(blade_count: int = 9, scale: float = 1.0, seed: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed * 1000.0) + blade_count * 17
	for i in blade_count:
		var ang := float(i) / float(blade_count) * TAU + rng.randf() * 0.55
		var h := (0.28 + rng.randf() * 0.42) * scale
		var w := (0.018 + rng.randf() * 0.022) * scale
		var bend := rng.randf_range(-0.12, 0.14) * scale
		var base := Vector3(cos(ang) * rng.randf_range(0.01, 0.06) * scale, 0.0, sin(ang) * rng.randf_range(0.01, 0.06) * scale)
		var mid := base + Vector3(cos(ang) * bend * 0.45, h * 0.55, sin(ang) * bend * 0.45)
		var tip := base + Vector3(cos(ang) * bend, h, sin(ang) * bend)
		var side := Vector3(-sin(ang), 0, cos(ang))
		# tapered blade as two tris
		_tri_colored(st, base - side * w, base + side * w, mid - side * w * 0.7, 0.0, 0.0, 0.55)
		_tri_colored(st, base + side * w, mid + side * w * 0.7, mid - side * w * 0.7, 0.0, 0.55, 0.55)
		_tri_colored(st, mid - side * w * 0.55, mid + side * w * 0.55, tip, 0.55, 0.55, 1.0)
	st.generate_normals()
	return st.commit()


static func rock(seed: float = 1.0, radius: float = 0.45) -> ArrayMesh:
	return uv_sphere(radius, 10, 14, 0.62, seed, 0.72)


static func stepping_stone(radius: float = 0.55, seed: float = 1.0) -> ArrayMesh:
	## 丸く削れた踏み石。下面は閉じず、地面に沈めて黒い円盤を出さない。
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 12
	var h := 0.06
	var top := Vector3(0, h * 1.1, 0)
	for j in segs:
		var a0 := float(j) / float(segs) * TAU
		var a1 := float(j + 1) / float(segs) * TAU
		var jagged0 := 1.0 + 0.1 * sin(a0 * 2.3 + seed) + 0.05 * sin(a0 * 5.1 + seed * 1.7)
		var jagged1 := 1.0 + 0.1 * sin(a1 * 2.3 + seed) + 0.05 * sin(a1 * 5.1 + seed * 1.7)
		var p0 := Vector3(cos(a0) * radius * jagged0, h, sin(a0) * radius * jagged0)
		var p1 := Vector3(cos(a1) * radius * jagged1, h, sin(a1) * radius * jagged1)
		p0.y += 0.01 * sin(a0 * 2.5 + seed)
		p1.y += 0.01 * sin(a1 * 2.5 + seed)
		var b0 := Vector3(p0.x * 0.94, -0.02, p0.z * 0.94)
		var b1 := Vector3(p1.x * 0.94, -0.02, p1.z * 0.94)
		_tri(st, top, p0, p1)
		_tri(st, b0, b1, p1)
		_tri(st, b0, p1, p0)
		# 下面は描かない（黒い影円盤の原因になる）
	st.generate_normals()
	return st.commit()


static func bush(rng: RandomNumberGenerator) -> ArrayMesh:
	## 小さな雲形低木（球の房にしない）
	return canopy_cloud(rng, rng.randf_range(0.55, 0.75))


static func cloak_mesh(width: float = 0.42, length: float = 0.55) -> ArrayMesh:
	## 後ろに広がるマント（曲面パッチ）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 8
	var rows := 6
	for r in rows:
		for c in cols:
			var u0 := float(c) / float(cols)
			var u1 := float(c + 1) / float(cols)
			var v0 := float(r) / float(rows)
			var v1 := float(r + 1) / float(rows)
			var p00 := _cloak_p(u0, v0, width, length)
			var p10 := _cloak_p(u1, v0, width, length)
			var p01 := _cloak_p(u0, v1, width, length)
			var p11 := _cloak_p(u1, v1, width, length)
			_tri(st, p00, p10, p01)
			_tri(st, p10, p11, p01)
	st.generate_normals()
	return st.commit()


static func _cloak_p(u: float, v: float, width: float, length: float) -> Vector3:
	var x := (u - 0.5) * width * (1.0 + v * 0.55)
	var y := -v * length
	var z := -0.05 - v * 0.22 - 0.04 * sin(u * PI)
	return Vector3(x, y, z)


static func _append_displaced_sphere(st: SurfaceTool, center: Vector3, radius: float, squash_y: float, rings: int, segs: int, displace: float, seed: float) -> void:
	for i in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		var y0 := cos(PI * v0)
		var y1 := cos(PI * v1)
		var r0 := sin(PI * v0)
		var r1 := sin(PI * v1)
		for j in segs:
			var u0 := float(j) / float(segs)
			var u1 := float(j + 1) / float(segs)
			var a0 := u0 * TAU
			var a1 := u1 * TAU
			var pts := [
				Vector3(r0 * cos(a0), y0 * squash_y, r0 * sin(a0)),
				Vector3(r0 * cos(a1), y0 * squash_y, r0 * sin(a1)),
				Vector3(r1 * cos(a0), y1 * squash_y, r1 * sin(a0)),
				Vector3(r1 * cos(a1), y1 * squash_y, r1 * sin(a1)),
			]
			for k in 4:
				var p: Vector3 = pts[k]
				p = p * (1.0 + (_noise3(p + center, seed) - 0.5) * displace)
				pts[k] = center + p * radius
			_tri_uv(st, pts[0], pts[1], pts[2], Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1))
			_tri_uv(st, pts[1], pts[3], pts[2], Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))


static func _leaf_quad(st: SurfaceTool, origin: Vector3, size: float, yaw: float, pitch: float, shade: float) -> void:
	var cy := cos(yaw)
	var sy := sin(yaw)
	var cp := cos(pitch)
	var sp := sin(pitch)
	var right := Vector3(cy, 0, -sy) * size
	var up := Vector3(sy * sp, cp, cy * sp) * size * 1.35
	var p0 := origin - right - up * 0.1
	var p1 := origin + right - up * 0.1
	var p2 := origin + right * 0.15 + up
	var p3 := origin - right * 0.15 + up
	_tri_colored(st, p0, p1, p2, shade, shade, shade + 0.2)
	_tri_colored(st, p0, p2, p3, shade, shade + 0.2, shade + 0.2)


static func _petal_mesh(size: float) -> ArrayMesh:
	return flower_petals(1, size)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _tri_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_uv(uc)
	st.add_vertex(c)


static func _tri_colored(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: float, cb: float, cc: float) -> void:
	st.set_color(Color(ca, ca, ca))
	st.add_vertex(a)
	st.set_color(Color(cb, cb, cb))
	st.add_vertex(b)
	st.set_color(Color(cc, cc, cc))
	st.add_vertex(c)


static func _mat(c: Color, rough: float = 0.82) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m
