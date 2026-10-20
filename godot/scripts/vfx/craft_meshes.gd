extends RefCounted
class_name CraftMeshes
## Forests 独自メッシュ。外部アセットに頼らず手で組む。


static func _noise3(p: Vector3, seed: float = 0.0) -> float:
	var n := sin(p.x * 1.7 + seed) * cos(p.z * 1.3 + seed * 1.1)
	n += 0.5 * sin(p.x * 3.1 + p.y * 2.2 + seed * 2.0)
	n += 0.25 * sin(p.z * 5.2 + p.x * 4.1 + seed)
	return n * 0.5 + 0.5


static func uv_sphere(radius: float, rings: int, segments: int, displace: float = 0.0, seed: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		var y0 := cos(PI * v0)
		var y1 := cos(PI * v1)
		var r0 := sin(PI * v0)
		var r1 := sin(PI * v1)
		for j in segments:
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			var a0 := u0 * TAU
			var a1 := u1 * TAU
			var p00 := Vector3(r0 * cos(a0), y0, r0 * sin(a0))
			var p10 := Vector3(r0 * cos(a1), y0, r0 * sin(a1))
			var p01 := Vector3(r1 * cos(a0), y1, r1 * sin(a0))
			var p11 := Vector3(r1 * cos(a1), y1, r1 * sin(a1))
			if displace > 0.0:
				p00 = p00 * (1.0 + (_noise3(p00, seed) - 0.5) * displace)
				p10 = p10 * (1.0 + (_noise3(p10, seed) - 0.5) * displace)
				p01 = p01 * (1.0 + (_noise3(p01, seed) - 0.5) * displace)
				p11 = p11 * (1.0 + (_noise3(p11, seed) - 0.5) * displace)
			_tri_uv(st, p00 * radius, p10 * radius, p01 * radius, Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1))
			_tri_uv(st, p10 * radius, p11 * radius, p01 * radius, Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
	st.generate_normals()
	return st.commit()


static func trunk(height: float, bottom_r: float, top_r: float, segments: int = 10, lean: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 6
	for i in rings:
		var t0 := float(i) / float(rings)
		var t1 := float(i + 1) / float(rings)
		var y0 := t0 * height
		var y1 := t1 * height
		var r0 := lerpf(bottom_r, top_r, t0)
		var r1 := lerpf(bottom_r, top_r, t1)
		var lean0 := lean * t0 * t0
		var lean1 := lean * t1 * t1
		for j in segments:
			var a0 := float(j) / float(segments) * TAU
			var a1 := float(j + 1) / float(segments) * TAU
			var p00 := Vector3(cos(a0) * r0 + lean0, y0, sin(a0) * r0)
			var p10 := Vector3(cos(a1) * r0 + lean0, y0, sin(a1) * r0)
			var p01 := Vector3(cos(a0) * r1 + lean1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1 + lean1, y1, sin(a1) * r1)
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			_tri_uv(st, p00, p10, p01, Vector2(u0, t0), Vector2(u1, t0), Vector2(u0, t1))
			_tri_uv(st, p10, p11, p01, Vector2(u1, t0), Vector2(u1, t1), Vector2(u0, t1))
	# cap top
	var top_y := height
	var top_lean := lean
	var top_c := Vector3(top_lean, top_y, 0)
	for j in segments:
		var a0 := float(j) / float(segments) * TAU
		var a1 := float(j + 1) / float(segments) * TAU
		var p0 := Vector3(cos(a0) * top_r + top_lean, top_y, sin(a0) * top_r)
		var p1 := Vector3(cos(a1) * top_r + top_lean, top_y, sin(a1) * top_r)
		_tri(st, top_c, p0, p1)
	st.generate_normals()
	return st.commit()


static func canopy_cluster(rng: RandomNumberGenerator, base_r: float = 1.0) -> ArrayMesh:
	## 複数の歪み球を一つのメッシュに結合した樹冠
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blobs := rng.randi_range(7, 11)
	for b in blobs:
		var center := Vector3(
			rng.randf_range(-0.55, 0.55) * base_r,
			rng.randf_range(-0.1, 0.7) * base_r,
			rng.randf_range(-0.55, 0.55) * base_r
		)
		var rad := base_r * rng.randf_range(0.38, 0.78)
		var squash := rng.randf_range(0.55, 0.9)
		_append_displaced_sphere(st, center, rad, squash, 8, 12, 0.32, float(b) * 13.0 + rng.randf() * 10.0)
	st.generate_normals()
	return st.commit()


static func pine_canopy(layers: int, base_r: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in layers:
		var t := float(i) / float(layers)
		var y := t * height
		var r := base_r * (1.0 - t * 0.78)
		var tip := Vector3(0, y + height / float(layers) * 1.15, 0)
		var segs := 9
		for j in segs:
			var a0 := float(j) / float(segs) * TAU
			var a1 := float(j + 1) / float(segs) * TAU
			# slightly jagged edge
			var jagged0 := 1.0 + 0.08 * sin(a0 * 3.0 + i)
			var jagged1 := 1.0 + 0.08 * sin(a1 * 3.0 + i)
			var p0 := Vector3(cos(a0) * r * jagged0, y, sin(a0) * r * jagged0)
			var p1 := Vector3(cos(a1) * r * jagged1, y, sin(a1) * r * jagged1)
			_tri(st, tip, p0, p1)
	st.generate_normals()
	return st.commit()


static func flower(petal_count: int, petal_color: Color, scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var stem := MeshInstance3D.new()
	stem.mesh = trunk(0.42 * scale, 0.025 * scale, 0.015 * scale, 6, 0.02)
	stem.material_override = _mat(Color(0.28, 0.52, 0.30))
	root.add_child(stem)

	var center := MeshInstance3D.new()
	center.mesh = uv_sphere(0.07 * scale, 6, 8)
	center.position.y = 0.44 * scale
	var cm := _mat(Color(0.95, 0.82, 0.28))
	cm.emission_enabled = true
	cm.emission = Color(0.95, 0.8, 0.3)
	cm.emission_energy_multiplier = 0.2
	center.material_override = cm
	root.add_child(center)

	var pmat := _mat(petal_color, 0.55)
	pmat.emission_enabled = true
	pmat.emission = petal_color
	pmat.emission_energy_multiplier = 0.12
	for i in petal_count:
		var petal := MeshInstance3D.new()
		petal.mesh = _petal_mesh(0.14 * scale)
		petal.material_override = pmat
		var ang := float(i) / float(petal_count) * TAU
		petal.position = Vector3(cos(ang) * 0.09 * scale, 0.45 * scale, sin(ang) * 0.09 * scale)
		petal.look_at(petal.position + Vector3(cos(ang), 0.35, sin(ang)), Vector3.UP)
		root.add_child(petal)
	return root


static func grass_clump(blade_count: int = 7, scale: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in blade_count:
		var ang := float(i) / float(blade_count) * TAU + randf() * 0.4
		var h := (0.35 + randf() * 0.35) * scale
		var w := (0.03 + randf() * 0.025) * scale
		var bend := randf_range(-0.08, 0.08) * scale
		var base := Vector3(cos(ang) * 0.04 * scale, 0.0, sin(ang) * 0.04 * scale)
		var tip := base + Vector3(cos(ang) * bend, h, sin(ang) * bend)
		var side := Vector3(-sin(ang), 0, cos(ang)) * w
		# vertex color as height for wind shader
		_tri_colored(st, base - side, base + side, tip, 0.0, 0.0, 1.0)
	st.generate_normals()
	return st.commit()


static func rock(seed: float = 1.0, radius: float = 0.45) -> ArrayMesh:
	return uv_sphere(radius, 8, 10, 0.55, seed)


static func stepping_stone(radius: float = 0.55) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 8
	var h := 0.06
	var top := Vector3(0, h, 0)
	for j in segs:
		var a0 := float(j) / float(segs) * TAU
		var a1 := float(j + 1) / float(segs) * TAU
		var jagged0 := 1.0 + 0.12 * sin(a0 * 2.5)
		var jagged1 := 1.0 + 0.12 * sin(a1 * 2.5)
		var p0 := Vector3(cos(a0) * radius * jagged0, h, sin(a0) * radius * jagged0)
		var p1 := Vector3(cos(a1) * radius * jagged1, h, sin(a1) * radius * jagged1)
		var b0 := Vector3(p0.x, 0, p0.z)
		var b1 := Vector3(p1.x, 0, p1.z)
		_tri(st, top, p0, p1)
		_tri(st, b0, b1, p1)
		_tri(st, b0, p1, p0)
	st.generate_normals()
	return st.commit()


static func bush(rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in rng.randi_range(4, 6):
		var c := Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(0.15, 0.45), rng.randf_range(-0.25, 0.25))
		_append_displaced_sphere(st, c, rng.randf_range(0.28, 0.48), 0.7, 6, 8, 0.28, rng.randf() * 40.0)
	st.generate_normals()
	return st.commit()


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


static func _petal_mesh(size: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := Vector3(0, size, 0)
	var left := Vector3(-size * 0.45, size * 0.2, 0)
	var right := Vector3(size * 0.45, size * 0.2, 0)
	var base := Vector3(0, 0, 0)
	_tri(st, base, left, tip)
	_tri(st, base, tip, right)
	st.generate_normals()
	return st.commit()


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
