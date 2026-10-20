extends Node3D
class_name WorldBuilder
## Forests 独自クラフトの森。外部キット非依存。


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_path()
	_make_water()
	_scatter_trees()
	_scatter_flowers_bushes_rocks()
	_scatter_grass()
	_make_boundary()
	_add_lights()
	_add_ambience()


func _clear_generated() -> void:
	var old := get_node_or_null("Generated")
	if old:
		old.free()
	var root := Node3D.new()
	root.name = "Generated"
	add_child(root)


func _gen() -> Node3D:
	return $Generated


func _mat(c: Color, rough: float = 0.84) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _make_ground() -> void:
	var ground := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = VisualKit.make_height_terrain(52.0, 64)
	mesh.material_override = VisualKit.terrain_material()
	ground.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(52, 2.0, 52)
	col.shape = shape
	col.position.y = -0.9
	ground.add_child(col)
	_gen().add_child(ground)


func _make_path() -> void:
	var stone_mat := _mat(Color(0.62, 0.56, 0.46), 0.92)
	for a in 20:
		var ang := a / 20.0 * TAU
		var x := cos(ang) * 3.45
		var z := sin(ang) * 3.45 + 2.55
		var y := VisualKit._h(x, z) + 0.02
		var stone := MeshInstance3D.new()
		stone.mesh = CraftMeshes.stepping_stone(0.48 + randf() * 0.12)
		stone.material_override = stone_mat
		stone.position = Vector3(x, y, z)
		stone.rotation_degrees.y = rad_to_deg(ang) + randf_range(-12, 12)
		_gen().add_child(stone)


func _make_water() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(8, -0.06, -6)
	_gen().add_child(pond)

	var water := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.35
	cyl.bottom_radius = 4.35
	cyl.height = 0.2
	cyl.radial_segments = 40
	water.mesh = cyl
	water.material_override = VisualKit.water_material()
	water.position.y = 0.12
	pond.add_child(water)

	# 岸の手作り岩
	for i in 16:
		var ang := i / 16.0 * TAU
		var r := 4.55 + randf_range(-0.2, 0.5)
		var rock := MeshInstance3D.new()
		rock.mesh = CraftMeshes.rock(10.0 + i * 2.7, randf_range(0.28, 0.55))
		rock.material_override = _mat(Color(0.52, 0.54, 0.55).lerp(Color(0.45, 0.48, 0.42), randf()), 0.8)
		rock.position = Vector3(cos(ang) * r, 0.05, sin(ang) * r)
		rock.rotation_degrees = Vector3(randf_range(-20, 20), randf() * 360.0, randf_range(-15, 15))
		rock.scale = Vector3(randf_range(0.9, 1.4), randf_range(0.45, 0.75), randf_range(0.9, 1.35))
		pond.add_child(rock)


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020
	for i in 40:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.8:
			continue
		if p.length() < 3.3:
			continue
		p.y = VisualKit._h(p.x, p.z)
		if rng.randf() > 0.68:
			_add_pine(p, rng)
		else:
			_add_deciduous(p, rng)

	# 遠景のシルエット木
	for i in 8:
		var ang := i / 8.0 * TAU + 0.2
		var p := Vector3(cos(ang) * 25.0, -0.15, sin(ang) * 25.0)
		_add_deciduous(p, rng, true)


func _add_deciduous(pos: Vector3, rng: RandomNumberGenerator, backdrop: bool = false) -> void:
	var h := rng.randf_range(1.9, 2.9) * (1.7 if backdrop else 1.0)
	var lean := rng.randf_range(-0.18, 0.18)
	var bark := VisualKit.bark_material(Color(0.42, 0.28, 0.18).lerp(Color(0.35, 0.22, 0.14), rng.randf()))
	var leaf_col := Color(0.36, 0.58, 0.34).lerp(Color(0.48, 0.68, 0.36), rng.randf())

	var trunk_mi := MeshInstance3D.new()
	trunk_mi.mesh = CraftMeshes.trunk(h, 0.28 if not backdrop else 0.4, 0.11 if not backdrop else 0.15, 11, lean)
	trunk_mi.material_override = bark

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.canopy_cluster(rng, rng.randf_range(1.05, 1.45) * (1.5 if backdrop else 1.0))
	canopy.material_override = VisualKit.foliage_material(leaf_col, leaf_col.darkened(0.32))
	canopy.position = Vector3(lean * 0.85, h * 0.92, 0)

	if backdrop:
		var n := Node3D.new()
		n.position = pos
		n.add_child(trunk_mi)
		n.add_child(canopy)
		_gen().add_child(n)
		return

	var body := Interactable.new()
	body.interact_id = "tree_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "葉ずれの木"
	body.examine_text = "樹皮に手を当てると、森の鼓動がする。"
	body.item_id = "softwood"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos
	body.add_child(trunk_mi)
	body.add_child(canopy)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.75
	shape.height = h + 1.2
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)
	_gen().add_child(body)


func _add_pine(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "pine_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "青葉の針葉樹"
	body.examine_text = "針葉の匂いが澄んでいる。"
	body.item_id = "pine_needle"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos

	var h := rng.randf_range(2.3, 3.4)
	var trunk_mi := MeshInstance3D.new()
	trunk_mi.mesh = CraftMeshes.trunk(h, 0.2, 0.07, 9, rng.randf_range(-0.08, 0.08))
	trunk_mi.material_override = VisualKit.bark_material(Color(0.34, 0.24, 0.17))
	body.add_child(trunk_mi)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.pine_canopy(rng.randi_range(4, 6), rng.randf_range(0.95, 1.35), h * 0.85)
	canopy.material_override = VisualKit.foliage_material(Color(0.22, 0.42, 0.30), Color(0.12, 0.28, 0.18))
	canopy.position.y = 0.35
	body.add_child(canopy)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = h + 1.0
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)
	_gen().add_child(body)


func _scatter_flowers_bushes_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var petal_cols := [
		Color(0.98, 0.78, 0.40),
		Color(0.95, 0.55, 0.68),
		Color(0.78, 0.72, 0.98),
		Color(0.95, 0.92, 0.65),
		Color(0.65, 0.82, 0.95),
	]

	for i in 34:
		var p := _rand_point(rng, 2.2, 5.0)
		p.y = VisualKit._h(p.x, p.z)
		var body := Interactable.new()
		body.interact_id = "flower_%d_%d" % [int(p.x * 10), int(p.z * 10)]
		body.display_name = "ひだまり草"
		body.examine_text = "花弁が光をすくっている。"
		body.item_id = "sunpetal"
		body.item_amount = 1
		body.position = p
		var flower := _make_flower(rng, petal_cols[rng.randi_range(0, petal_cols.size() - 1)])
		body.add_child(flower)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		col.shape = shape
		col.position.y = 0.25
		body.add_child(col)
		_gen().add_child(body)

	for i in 14:
		var p := _rand_point(rng, 2.5, 4.0)
		p.y = VisualKit._h(p.x, p.z)
		var body := Interactable.new()
		body.interact_id = "moss_%d_%d" % [int(p.x * 10), int(p.z * 10)]
		body.display_name = "こけの茂み"
		body.examine_text = "緑が息をしている。"
		body.item_id = "moss_tuft"
		body.item_amount = 1
		body.position = p
		var bush := MeshInstance3D.new()
		bush.mesh = CraftMeshes.bush(rng)
		var bc := Color(0.30, 0.50, 0.32).lerp(Color(0.38, 0.58, 0.34), rng.randf())
		bush.material_override = VisualKit.foliage_material(bc, bc.darkened(0.28))
		body.add_child(bush)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.65
		col.shape = shape
		col.position.y = 0.3
		body.add_child(col)
		_gen().add_child(body)

	for i in 16:
		var p := _rand_point(rng, 3.0, 5.5)
		p.y = VisualKit._h(p.x, p.z)
		var body := Interactable.new()
		body.interact_id = "rock_%d_%d" % [int(p.x * 10), int(p.z * 10)]
		body.display_name = "苔むした岩"
		body.examine_text = "冷たくて、丸い。"
		body.item_id = "river_pebble"
		body.item_amount = 1
		body.position = p
		var rock := MeshInstance3D.new()
		rock.mesh = CraftMeshes.rock(rng.randf() * 100.0, rng.randf_range(0.32, 0.62))
		rock.material_override = _mat(Color(0.5, 0.52, 0.54).lerp(Color(0.44, 0.48, 0.42), rng.randf()), 0.78)
		rock.scale = Vector3(rng.randf_range(0.9, 1.5), rng.randf_range(0.5, 0.8), rng.randf_range(0.9, 1.4))
		rock.rotation_degrees = Vector3(rng.randf_range(-25, 25), rng.randf() * 360.0, rng.randf_range(-20, 20))
		body.add_child(rock)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.5
		col.shape = shape
		col.position.y = 0.2
		body.add_child(col)
		_gen().add_child(body)


func _make_flower(rng: RandomNumberGenerator, petal_col: Color) -> Node3D:
	var root := Node3D.new()
	var stem := MeshInstance3D.new()
	stem.mesh = CraftMeshes.trunk(0.4, 0.022, 0.014, 6, rng.randf_range(-0.03, 0.03))
	stem.material_override = _mat(Color(0.26, 0.5, 0.28))
	root.add_child(stem)

	var center := MeshInstance3D.new()
	center.mesh = CraftMeshes.uv_sphere(0.065, 5, 7)
	center.position.y = 0.42
	var cm := _mat(Color(0.95, 0.82, 0.3), 0.45)
	cm.emission_enabled = true
	cm.emission = Color(0.95, 0.8, 0.25)
	cm.emission_energy_multiplier = 0.25
	center.material_override = cm
	root.add_child(center)

	var pmat := _mat(petal_col, 0.5)
	pmat.emission_enabled = true
	pmat.emission = petal_col
	pmat.emission_energy_multiplier = 0.15
	var count := rng.randi_range(5, 7)
	for i in count:
		var petal := MeshInstance3D.new()
		# rebuild small petal via sphere squash as safe alternative to look_at
		var sm := SphereMesh.new()
		sm.radius = 0.1
		petal.mesh = sm
		petal.material_override = pmat
		var ang := float(i) / float(count) * TAU
		petal.position = Vector3(cos(ang) * 0.1, 0.43, sin(ang) * 0.1)
		petal.scale = Vector3(1.15, 0.35, 0.7)
		petal.rotation_degrees.y = rad_to_deg(ang)
		root.add_child(petal)
	return root


func _scatter_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var gmat := VisualKit.grass_material()
	for i in 180:
		var p := _rand_point(rng, 2.0, 5.0)
		p.y = VisualKit._h(p.x, p.z)
		var grass := MeshInstance3D.new()
		grass.mesh = CraftMeshes.grass_clump(rng.randi_range(5, 9), rng.randf_range(0.85, 1.4))
		grass.material_override = gmat
		grass.position = p
		grass.rotation_degrees.y = rng.randf() * 360.0
		grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_gen().add_child(grass)


func _rand_point(rng: RandomNumberGenerator, min_len: float, pond_clear: float) -> Vector3:
	for _i in 40:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.length() < min_len:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < pond_clear:
			continue
		return p
	return Vector3(rng.randf_range(4, 10), 0, rng.randf_range(4, 10))


func _add_lights() -> void:
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.72, 0.86, 1.0)
	fill.light_energy = 0.9
	fill.omni_range = 42.0
	fill.position = Vector3(-9, 11, 12)
	_gen().add_child(fill)

	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.84, 0.62)
	warm.light_energy = 0.75
	warm.omni_range = 30.0
	warm.position = Vector3(11, 6, -3)
	_gen().add_child(warm)

	var ground := OmniLight3D.new()
	ground.light_color = Color(0.5, 0.68, 0.42)
	ground.light_energy = 0.4
	ground.omni_range = 28.0
	ground.position = Vector3(0, 1.2, 2)
	_gen().add_child(ground)


func _add_ambience() -> void:
	var pollen := GPUParticles3D.new()
	pollen.amount = 56
	pollen.lifetime = 10.0
	pollen.preprocess = 3.0
	pollen.visibility_aabb = AABB(Vector3(-22, 0, -22), Vector3(44, 14, 44))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 2.5, 16)
	mat.direction = Vector3(0.15, 0.5, 0.1)
	mat.spread = 50.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.35
	mat.gravity = Vector3(0, 0.012, 0)
	mat.scale_min = 0.035
	mat.scale_max = 0.09
	mat.color = Color(1.0, 0.94, 0.72, 0.85)
	pollen.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.5
	pollen.draw_pass_1 = draw
	pollen.position = Vector3(0, 2.8, 0)
	_gen().add_child(pollen)


func _make_boundary() -> void:
	for dir in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		if abs(dir.x) > 0:
			shape.size = Vector3(1, 8, 56)
			wall.position = dir * 26.5
		else:
			shape.size = Vector3(56, 8, 1)
			wall.position = dir * 26.5
		col.shape = shape
		col.position.y = 3
		wall.add_child(col)
		_gen().add_child(wall)
