extends Node3D
class_name WorldBuilder
## Forests 手組みの森。密度・光・造形を妥協なく組む。


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
	mesh.mesh = VisualKit.make_height_terrain(52.0, 72)
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
	var stone_mat := _mat(Color(0.62, 0.58, 0.5), 0.9)
	stone_mat.albedo_color = Color(0.66, 0.62, 0.54)
	for a in 22:
		var ang := a / 22.0 * TAU
		var x := cos(ang) * 3.4
		var z := sin(ang) * 3.4 + 2.5
		var y := VisualKit._h(x, z) + 0.015
		var stone := MeshInstance3D.new()
		stone.mesh = CraftMeshes.stepping_stone(0.42 + randf() * 0.16, float(a) * 3.1)
		stone.material_override = stone_mat
		stone.position = Vector3(x, y, z)
		stone.rotation_degrees.y = rad_to_deg(ang) + randf_range(-18, 18)
		_gen().add_child(stone)


func _make_water() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(8, -0.04, -6)
	_gen().add_child(pond)

	# bed
	var bed := MeshInstance3D.new()
	var bed_m := CylinderMesh.new()
	bed_m.top_radius = 4.5
	bed_m.bottom_radius = 4.5
	bed_m.height = 0.08
	bed_m.radial_segments = 48
	bed.mesh = bed_m
	bed.material_override = _mat(Color(0.32, 0.42, 0.36), 0.95)
	bed.position.y = -0.05
	pond.add_child(bed)

	var water := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.35
	cyl.bottom_radius = 4.35
	cyl.height = 0.18
	cyl.radial_segments = 48
	water.mesh = cyl
	water.material_override = VisualKit.water_material()
	water.position.y = 0.1
	pond.add_child(water)

	for i in 20:
		var ang := i / 20.0 * TAU
		var r := 4.5 + randf_range(-0.15, 0.55)
		var rock := MeshInstance3D.new()
		rock.mesh = CraftMeshes.rock(12.0 + i * 3.1, randf_range(0.3, 0.58))
		rock.material_override = _mat(Color(0.5, 0.5, 0.46).lerp(Color(0.4, 0.46, 0.38), randf()), 0.82)
		rock.position = Vector3(cos(ang) * r, 0.04, sin(ang) * r)
		rock.rotation_degrees = Vector3(randf_range(-18, 18), randf() * 360.0, randf_range(-12, 12))
		rock.scale = Vector3(randf_range(0.95, 1.45), randf_range(0.42, 0.72), randf_range(0.95, 1.4))
		pond.add_child(rock)


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020
	for i in 48:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.8:
			continue
		if p.length() < 3.4:
			continue
		p.y = VisualKit._h(p.x, p.z)
		if rng.randf() > 0.7:
			_add_pine(p, rng)
		else:
			_add_deciduous(p, rng)

	for i in 10:
		var ang := i / 10.0 * TAU + 0.15
		var p := Vector3(cos(ang) * 24.5, -0.1, sin(ang) * 24.5)
		_add_deciduous(p, rng, true)


func _add_deciduous(pos: Vector3, rng: RandomNumberGenerator, backdrop: bool = false) -> void:
	var h := rng.randf_range(2.05, 3.05) * (1.65 if backdrop else 1.0)
	var lean := rng.randf_range(-0.16, 0.16)
	var bark := VisualKit.bark_material(Color(0.45, 0.30, 0.19).lerp(Color(0.36, 0.23, 0.14), rng.randf()))
	var leaf_col := Color(0.30, 0.55, 0.30).lerp(Color(0.42, 0.64, 0.34), rng.randf())
	var leaf_dark := leaf_col.darkened(0.38)

	var trunk_mi := MeshInstance3D.new()
	trunk_mi.mesh = CraftMeshes.trunk(h, 0.26 if not backdrop else 0.38, 0.1 if not backdrop else 0.14, 14, lean, 0.05)
	trunk_mi.material_override = bark

	# secondary branches
	var branch_root := Node3D.new()
	branch_root.position = Vector3(lean * 0.4, h * 0.55, 0)
	var branch_count := 3 if backdrop else rng.randi_range(3, 5)
	for b in branch_count:
		var br := MeshInstance3D.new()
		br.mesh = CraftMeshes.branch(rng.randf_range(0.45, 0.85), 0.06, 0.02, 6, rng.randf_range(0.1, 0.28))
		br.material_override = bark
		var ang := float(b) / float(branch_count) * TAU + rng.randf() * 0.4
		br.position = Vector3(cos(ang) * 0.08, rng.randf_range(0.0, h * 0.25), sin(ang) * 0.08)
		br.rotation = Vector3(rng.randf_range(0.5, 1.1), ang, rng.randf_range(-0.2, 0.2))
		branch_root.add_child(br)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(1.15, 1.55) * (1.45 if backdrop else 1.0))
	canopy.material_override = VisualKit.foliage_material(leaf_col, leaf_dark)
	canopy.position = Vector3(lean * 0.9, h * 0.88, 0)

	var cards := MeshInstance3D.new()
	cards.mesh = CraftMeshes.leaf_cards(rng, 28 if backdrop else 42, rng.randf_range(0.85, 1.2) * (1.3 if backdrop else 1.0))
	cards.material_override = VisualKit.foliage_material(leaf_col.lightened(0.08), leaf_dark)
	cards.position = canopy.position
	cards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if backdrop:
		var n := Node3D.new()
		n.position = pos
		n.add_child(trunk_mi)
		n.add_child(branch_root)
		n.add_child(canopy)
		n.add_child(cards)
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
	body.add_child(branch_root)
	body.add_child(canopy)
	body.add_child(cards)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = h + 1.3
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

	var h := rng.randf_range(2.5, 3.6)
	var trunk_mi := MeshInstance3D.new()
	trunk_mi.mesh = CraftMeshes.trunk(h, 0.18, 0.06, 12, rng.randf_range(-0.07, 0.07), 0.035)
	trunk_mi.material_override = VisualKit.bark_material(Color(0.34, 0.24, 0.17))
	body.add_child(trunk_mi)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.pine_canopy(rng.randi_range(5, 7), rng.randf_range(1.0, 1.4), h * 0.88)
	canopy.material_override = VisualKit.foliage_material(Color(0.20, 0.42, 0.30), Color(0.10, 0.26, 0.16))
	canopy.position.y = 0.28
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
		Color(0.98, 0.72, 0.38),
		Color(0.95, 0.52, 0.66),
		Color(0.72, 0.68, 0.96),
		Color(0.96, 0.94, 0.7),
		Color(0.62, 0.82, 0.95),
		Color(0.95, 0.62, 0.48),
	]

	for i in 48:
		var p := _rand_point(rng, 2.2, 5.0)
		p.y = VisualKit._h(p.x, p.z)
		var body := Interactable.new()
		body.interact_id = "flower_%d_%d" % [int(p.x * 10), int(p.z * 10)]
		body.display_name = "ひだまり草"
		body.examine_text = "花弁が光をすくっている。"
		body.item_id = "sunpetal"
		body.item_amount = 1
		body.position = p
		body.add_child(_make_flower(rng, petal_cols[rng.randi_range(0, petal_cols.size() - 1)]))
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		col.shape = shape
		col.position.y = 0.25
		body.add_child(col)
		_gen().add_child(body)

	for i in 18:
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
		var bc := Color(0.28, 0.5, 0.3).lerp(Color(0.36, 0.58, 0.32), rng.randf())
		bush.material_override = VisualKit.foliage_material(bc, bc.darkened(0.3))
		body.add_child(bush)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.65
		col.shape = shape
		col.position.y = 0.3
		body.add_child(col)
		_gen().add_child(body)

	for i in 18:
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
		rock.mesh = CraftMeshes.rock(rng.randf() * 100.0, rng.randf_range(0.34, 0.65))
		rock.material_override = _mat(Color(0.5, 0.5, 0.48).lerp(Color(0.4, 0.46, 0.38), rng.randf()), 0.8)
		rock.scale = Vector3(rng.randf_range(0.95, 1.55), rng.randf_range(0.48, 0.78), rng.randf_range(0.95, 1.45))
		rock.rotation_degrees = Vector3(rng.randf_range(-22, 22), rng.randf() * 360.0, rng.randf_range(-18, 18))
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
	stem.mesh = CraftMeshes.trunk(0.42, 0.02, 0.012, 7, rng.randf_range(-0.04, 0.04), 0.0)
	stem.material_override = _mat(Color(0.24, 0.52, 0.28))
	root.add_child(stem)

	var center := MeshInstance3D.new()
	center.mesh = CraftMeshes.uv_sphere(0.055, 6, 8, 0.08, rng.randf() * 10.0)
	center.position.y = 0.44
	var cm := _mat(Color(0.96, 0.84, 0.32), 0.4)
	cm.emission_enabled = true
	cm.emission = Color(0.96, 0.82, 0.28)
	cm.emission_energy_multiplier = 0.35
	center.material_override = cm
	root.add_child(center)

	var petals := MeshInstance3D.new()
	petals.mesh = CraftMeshes.flower_petals(rng.randi_range(5, 7), rng.randf_range(0.13, 0.18))
	petals.position.y = 0.44
	var pmat := _mat(petal_col, 0.45)
	pmat.emission_enabled = true
	pmat.emission = petal_col
	pmat.emission_energy_multiplier = 0.2
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	petals.material_override = pmat
	root.add_child(petals)

	# tiny leaf pair on stem
	for side in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.mesh = CraftMeshes.flower_petals(1, 0.1)
		leaf.material_override = _mat(Color(0.3, 0.55, 0.3), 0.7)
		leaf.position = Vector3(0.02 * side, 0.2, 0)
		leaf.rotation = Vector3(-0.4, 0.0, 0.9 * side)
		root.add_child(leaf)
	return root


func _scatter_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var gmat := VisualKit.grass_material()
	for i in 320:
		var p := _rand_point(rng, 1.8, 4.8)
		p.y = VisualKit._h(p.x, p.z)
		var grass := MeshInstance3D.new()
		grass.mesh = CraftMeshes.grass_clump(rng.randi_range(7, 12), rng.randf_range(0.9, 1.55), float(i) * 1.7)
		grass.material_override = gmat
		grass.position = p
		grass.rotation_degrees.y = rng.randf() * 360.0
		grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_gen().add_child(grass)


func _rand_point(rng: RandomNumberGenerator, min_len: float, pond_clear: float) -> Vector3:
	for _i in 50:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.length() < min_len:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < pond_clear:
			continue
		return p
	return Vector3(rng.randf_range(4, 10), 0, rng.randf_range(4, 10))


func _add_lights() -> void:
	# soft sky fill (cool)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.68, 0.82, 0.98)
	fill.light_energy = 1.05
	fill.omni_range = 48.0
	fill.position = Vector3(-10, 12, 14)
	_gen().add_child(fill)

	# warm key bounce
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.86, 0.64)
	warm.light_energy = 0.95
	warm.omni_range = 34.0
	warm.position = Vector3(12, 7, -4)
	_gen().add_child(warm)

	# ground bounce green
	var ground := OmniLight3D.new()
	ground.light_color = Color(0.55, 0.72, 0.42)
	ground.light_energy = 0.55
	ground.omni_range = 30.0
	ground.position = Vector3(0, 1.4, 2)
	_gen().add_child(ground)

	# pond sparkle
	var pond_l := OmniLight3D.new()
	pond_l.light_color = Color(0.7, 0.92, 0.95)
	pond_l.light_energy = 0.7
	pond_l.omni_range = 10.0
	pond_l.position = Vector3(8, 1.5, -6)
	_gen().add_child(pond_l)


func _add_ambience() -> void:
	var pollen := GPUParticles3D.new()
	pollen.amount = 72
	pollen.lifetime = 11.0
	pollen.preprocess = 4.0
	pollen.visibility_aabb = AABB(Vector3(-22, 0, -22), Vector3(44, 14, 44))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 2.8, 16)
	mat.direction = Vector3(0.12, 0.55, 0.08)
	mat.spread = 55.0
	mat.initial_velocity_min = 0.08
	mat.initial_velocity_max = 0.32
	mat.gravity = Vector3(0, 0.01, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.085
	mat.color = Color(1.0, 0.95, 0.75, 0.9)
	pollen.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.5
	pollen.draw_pass_1 = draw
	pollen.position = Vector3(0, 2.8, 0)
	_gen().add_child(pollen)

	# secondary soft motes
	var motes := GPUParticles3D.new()
	motes.amount = 36
	motes.lifetime = 8.0
	motes.preprocess = 2.0
	motes.visibility_aabb = AABB(Vector3(-18, 0, -18), Vector3(36, 12, 36))
	var mat2 := ParticleProcessMaterial.new()
	mat2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat2.emission_box_extents = Vector3(12, 2, 12)
	mat2.direction = Vector3(-0.1, 0.4, 0.15)
	mat2.spread = 40.0
	mat2.initial_velocity_min = 0.05
	mat2.initial_velocity_max = 0.2
	mat2.gravity = Vector3(0, 0.008, 0)
	mat2.scale_min = 0.02
	mat2.scale_max = 0.05
	mat2.color = Color(0.85, 0.95, 1.0, 0.7)
	motes.process_material = mat2
	motes.draw_pass_1 = draw
	motes.position = Vector3(2, 3.2, -1)
	_gen().add_child(motes)


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
