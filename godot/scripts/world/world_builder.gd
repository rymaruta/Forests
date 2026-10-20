extends Node3D
class_name WorldBuilder
## 温かみのあるスタイライズド森（プリミティブ組み合わせ・自作のみ）


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_path_ring()
	_make_water()
	_scatter_nature()
	_make_boundary()
	_add_fill_light()


func _clear_generated() -> void:
	var old := get_node_or_null("Generated")
	if old:
		old.free()
	var root := Node3D.new()
	root.name = "Generated"
	add_child(root)


func _gen() -> Node3D:
	return $Generated


func _mat(color: Color, rough: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


func _make_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"

	# 大きな草地
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(52, 52)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	mesh.mesh = plane
	mesh.material_override = _mat(Color(0.42, 0.58, 0.36), 0.92)
	ground.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(52, 0.4, 52)
	col.shape = shape
	col.position.y = -0.2
	ground.add_child(col)
	_gen().add_child(ground)

	# 色の違う草地パッチで単調さを消す
	var palette := [
		Color(0.34, 0.52, 0.30),
		Color(0.48, 0.62, 0.38),
		Color(0.30, 0.46, 0.32),
		Color(0.55, 0.64, 0.40),
		Color(0.38, 0.50, 0.28),
	]
	for i in 36:
		var patch := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(2.0, 5.5), 0.06, randf_range(2.0, 5.5))
		patch.mesh = box
		patch.material_override = _mat(palette[i % palette.size()], 0.95)
		patch.position = Vector3(randf_range(-20, 20), 0.03, randf_range(-20, 20))
		patch.rotation_degrees.y = randf_range(0, 360)
		_gen().add_child(patch)

	# 草の束（細い円柱の群れ）
	for i in 90:
		var clump := Node3D.new()
		clump.position = Vector3(randf_range(-18, 18), 0, randf_range(-18, 18))
		if clump.position.length() < 2.2:
			continue
		for j in randi_range(3, 6):
			var blade := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.01
			cyl.bottom_radius = 0.025
			cyl.height = randf_range(0.25, 0.55)
			blade.mesh = cyl
			blade.material_override = _mat(Color(0.28 + randf() * 0.15, 0.48 + randf() * 0.12, 0.22), 0.9)
			blade.position = Vector3(randf_range(-0.15, 0.15), cyl.height * 0.5, randf_range(-0.15, 0.15))
			blade.rotation_degrees.z = randf_range(-12, 12)
			blade.rotation_degrees.x = randf_range(-8, 8)
			clump.add_child(blade)
		_gen().add_child(clump)


func _make_path_ring() -> void:
	# スポーン周りに柔らかい土の道
	for a in 16:
		var ang := a / 16.0 * TAU
		var p := Vector3(cos(ang) * 3.2, 0.02, sin(ang) * 3.2 + 2.5)
		var dirt := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 0.05, 0.7)
		dirt.mesh = box
		dirt.material_override = _mat(Color(0.52, 0.40, 0.28), 0.95)
		dirt.position = p
		dirt.look_at(Vector3(0, 0.02, 2.5), Vector3.UP)
		_gen().add_child(dirt)


func _make_water() -> void:
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.position = Vector3(8, 0, -6)
	_gen().add_child(pond)

	# 砂浜の縁
	var shore := MeshInstance3D.new()
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = 5.2
	shore_mesh.bottom_radius = 5.2
	shore_mesh.height = 0.08
	shore.mesh = shore_mesh
	shore.material_override = _mat(Color(0.72, 0.66, 0.48), 0.9)
	shore.position.y = 0.02
	pond.add_child(shore)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 4.4
	water_mesh.bottom_radius = 4.4
	water_mesh.height = 0.12
	water.mesh = water_mesh
	var wmat := _mat(Color(0.22, 0.52, 0.58, 0.72), 0.08, 0.35)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.albedo_color = Color(0.22, 0.52, 0.58, 0.72)
	wmat.rim_enabled = true
	wmat.rim = 0.4
	water.material_override = wmat
	water.position.y = 0.06
	pond.add_child(water)

	# 水辺の石
	for i in 10:
		var ang := i / 10.0 * TAU + 0.2
		var r := 4.6 + randf_range(-0.3, 0.5)
		_add_rock(Vector3(8 + cos(ang) * r, 0, -6 + sin(ang) * r), "river_pebble", "川辺の石")


func _scatter_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020

	for i in 34:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.5:
			continue
		if p.length() < 3.0:
			continue
		_add_tree(p, rng)

	for i in 22:
		var p := Vector3(rng.randf_range(-15, 15), 0, rng.randf_range(-15, 15))
		if p.length() < 2.2:
			continue
		_add_flower(p, rng)

	for i in 12:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.distance_to(Vector3(8, 0, -6)) < 5.0:
			continue
		_add_rock(p, "river_pebble", "苔むした岩")

	for i in 10:
		var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		_add_moss_clump(p)

	# 遠景の低い丘シルエット
	for i in 5:
		var hill := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = rng.randf_range(4.0, 7.0)
		s.height = s.radius * 0.55
		hill.mesh = s
		hill.material_override = _mat(Color(0.36, 0.50, 0.34), 0.95)
		var ang := i / 5.0 * TAU
		hill.position = Vector3(cos(ang) * 28.0, -1.2, sin(ang) * 28.0)
		_gen().add_child(hill)


func _add_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "tree_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "葉ずれの木"
	body.examine_text = "樹皮が温かい。折れた枝が採れそうだ。"
	body.item_id = "softwood"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos

	var trunk_h := rng.randf_range(1.6, 2.6)
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.32
	cyl.height = trunk_h
	trunk.mesh = cyl
	trunk.material_override = _mat(Color(0.38, 0.24, 0.15), 0.88)
	trunk.position.y = trunk_h * 0.5
	body.add_child(trunk)

	# 複数の葉球でシルエットを豊かに
	var canopy_color := Color(0.26 + rng.randf() * 0.1, 0.48 + rng.randf() * 0.12, 0.28)
	var dark := canopy_color.darkened(0.12)
	for k in 4:
		var leaves := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.55, 0.95)
		leaves.mesh = sphere
		leaves.material_override = _mat(canopy_color if k < 2 else dark, 0.82)
		leaves.position = Vector3(
			rng.randf_range(-0.25, 0.25),
			trunk_h + 0.35 + k * 0.18,
			rng.randf_range(-0.25, 0.25)
		)
		leaves.scale = Vector3(1.0 + rng.randf() * 0.3, 0.85, 1.0 + rng.randf() * 0.3)
		body.add_child(leaves)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = trunk_h + 1.2
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)
	_gen().add_child(body)


func _add_flower(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "flower_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "ひだまり草"
	body.examine_text = "小さな花が揺れている。花弁をそっと摘めそうだ。"
	body.item_id = "sunpetal"
	body.item_amount = 1
	body.position = pos

	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.035
	cyl.height = 0.42
	stem.mesh = cyl
	stem.material_override = _mat(Color(0.22, 0.48, 0.24), 0.9)
	stem.position.y = 0.21
	body.add_child(stem)

	var petal_cols := [
		Color(0.95, 0.72, 0.32),
		Color(0.92, 0.55, 0.62),
		Color(0.85, 0.78, 0.95),
		Color(0.98, 0.88, 0.55),
	]
	var base_col: Color = petal_cols[rng.randi_range(0, petal_cols.size() - 1)]
	for p in 5:
		var petal := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.09
		petal.mesh = sphere
		petal.material_override = _mat(base_col, 0.55)
		var ang := p / 5.0 * TAU
		petal.position = Vector3(cos(ang) * 0.1, 0.45, sin(ang) * 0.1)
		petal.scale = Vector3(1.1, 0.45, 0.8)
		body.add_child(petal)

	var center := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.07
	center.mesh = cs
	center.material_override = _mat(Color(0.95, 0.85, 0.35), 0.4)
	center.position.y = 0.46
	body.add_child(center)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	col.position.y = 0.25
	body.add_child(col)
	_gen().add_child(body)


func _add_rock(pos: Vector3, item: String, label: String) -> void:
	var body := Interactable.new()
	body.interact_id = "rock_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = label
	body.examine_text = "手のひらに収まる石。ポケットに入れられそうだ。"
	body.item_id = item
	body.item_amount = 1
	body.position = pos

	var mesh := MeshInstance3D.new()
	# 角ばった岩ではなく少し丸み
	var sphere := SphereMesh.new()
	sphere.radius = randf_range(0.28, 0.55)
	sphere.height = sphere.radius * randf_range(0.9, 1.3)
	mesh.mesh = sphere
	mesh.material_override = _mat(Color(0.50, 0.52, 0.54).lerp(Color(0.45, 0.48, 0.42), randf()), 0.78)
	mesh.position.y = sphere.height * 0.28
	mesh.scale = Vector3(randf_range(0.9, 1.4), randf_range(0.55, 0.85), randf_range(0.9, 1.3))
	mesh.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-10, 10))
	body.add_child(mesh)

	# 苔
	if randf() > 0.45:
		var moss := MeshInstance3D.new()
		var ms := SphereMesh.new()
		ms.radius = 0.12
		moss.mesh = ms
		moss.material_override = _mat(Color(0.32, 0.48, 0.30), 0.95)
		moss.position = mesh.position + Vector3(0.05, 0.12, 0.02)
		moss.scale = Vector3(1.4, 0.4, 1.1)
		body.add_child(moss)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	col.shape = shape
	col.position.y = 0.2
	body.add_child(col)
	_gen().add_child(body)


func _add_moss_clump(pos: Vector3) -> void:
	var body := Interactable.new()
	body.interact_id = "moss_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "こけの丘"
	body.examine_text = "湿った香り。こけ房が採れそうだ。"
	body.item_id = "moss_tuft"
	body.item_amount = 1
	body.position = pos

	for i in 3:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.28 + i * 0.05
		mesh.mesh = sphere
		mesh.material_override = _mat(Color(0.28 + i * 0.04, 0.46 + i * 0.03, 0.30), 0.95)
		mesh.position = Vector3(randf_range(-0.15, 0.15), 0.1, randf_range(-0.15, 0.15))
		mesh.scale = Vector3(1.3, 0.4, 1.1)
		body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	col.shape = shape
	col.position.y = 0.1
	body.add_child(col)
	_gen().add_child(body)


func _add_fill_light() -> void:
	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.75, 0.88, 1.0)
	fill.light_energy = 0.35
	fill.omni_range = 28.0
	fill.position = Vector3(-6, 8, 10)
	_gen().add_child(fill)

	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.85, 0.6)
	warm.light_energy = 0.25
	warm.omni_range = 18.0
	warm.position = Vector3(10, 5, -4)
	_gen().add_child(warm)


func _make_boundary() -> void:
	for dir in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		if abs(dir.x) > 0:
			shape.size = Vector3(1, 6, 54)
			wall.position = dir * 26.0
		else:
			shape.size = Vector3(54, 6, 1)
			wall.position = dir * 26.0
		col.shape = shape
		col.position.y = 3
		wall.add_child(col)
		_gen().add_child(wall)
