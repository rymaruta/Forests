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


static func trunk(height: float, bottom_r: float, top_r: float, segments: int = 12, lean: float = 0.0, bark_ripple: float = 0.04) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 10
	for i in rings:
		var t0 := float(i) / float(rings)
		var t1 := float(i + 1) / float(rings)
		var y0 := t0 * height
		var y1 := t1 * height
		var r0 := lerpf(bottom_r, top_r, t0 * t0 * 0.35 + t0 * 0.65)
		var r1 := lerpf(bottom_r, top_r, t1 * t1 * 0.35 + t1 * 0.65)
		# root flare near ground
		if t0 < 0.12:
			r0 *= lerpf(1.55, 1.0, t0 / 0.12)
		if t1 < 0.12:
			r1 *= lerpf(1.55, 1.0, t1 / 0.12)
		var lean0 := lean * t0 * t0
		var lean1 := lean * t1 * t1
		for j in segments:
			var a0 := float(j) / float(segments) * TAU
			var a1 := float(j + 1) / float(segments) * TAU
			var ripple0 := 1.0 + bark_ripple * sin(a0 * 5.0 + t0 * 8.0)
			var ripple1 := 1.0 + bark_ripple * sin(a1 * 5.0 + t0 * 8.0)
			var ripple2 := 1.0 + bark_ripple * sin(a0 * 5.0 + t1 * 8.0)
			var ripple3 := 1.0 + bark_ripple * sin(a1 * 5.0 + t1 * 8.0)
			var p00 := Vector3(cos(a0) * r0 * ripple0 + lean0, y0, sin(a0) * r0 * ripple0)
			var p10 := Vector3(cos(a1) * r0 * ripple1 + lean0, y0, sin(a1) * r0 * ripple1)
			var p01 := Vector3(cos(a0) * r1 * ripple2 + lean1, y1, sin(a0) * r1 * ripple2)
			var p11 := Vector3(cos(a1) * r1 * ripple3 + lean1, y1, sin(a1) * r1 * ripple3)
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			_tri_uv(st, p00, p10, p01, Vector2(u0, t0), Vector2(u1, t0), Vector2(u0, t1))
			_tri_uv(st, p10, p11, p01, Vector2(u1, t0), Vector2(u1, t1), Vector2(u0, t1))
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
	## 参照のふわっと雲冠。複数球を重ねず、1枚の高分割シェルでコブを出す。
	## （球の継ぎ目＝プラスチック感の主因だった）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lobes := rng.randi_range(5, 7)
	var lobe_amp := rng.randf_range(0.18, 0.26)
	var phase := rng.randf() * TAU
	var squash := rng.randf_range(0.9, 1.0)
	var rings := 18
	var segs := 36
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
