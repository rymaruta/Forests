extends Node3D
class_name WorldBuilder
## Forests 世界。全部手組み、構図ごと作り込む。


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_path()
	_make_water()
	_make_cottage()
	_scatter_trees()
	_scatter_flowers_bushes_rocks()
	_scatter_grass()
	_make_spawn_garden()
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
	mesh.mesh = VisualKit.make_height_terrain(52.0, 80)
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
	# ring around spawn
	for a in 24:
		var ang := a / 24.0 * TAU
		_place_stone(cos(ang) * 3.35, sin(ang) * 3.35 + 2.5, float(a))
	# path toward cottage
	for i in 14:
		var t := float(i) / 13.0
		var x := lerpf(0.0, -5.2, t) + sin(t * 3.0) * 0.35
		var z := lerpf(2.5, 4.0, t) + cos(t * 2.0) * 0.2
		_place_stone(x, z, 100.0 + float(i))
	# path toward pond
	for i in 12:
		var t := float(i) / 11.0
		var x := lerpf(1.5, 7.2, t) + sin(t * 4.0) * 0.25
		var z := lerpf(1.0, -4.5, t)
		_place_stone(x, z, 200.0 + float(i))


func _place_stone(x: float, z: float, seed: float) -> void:
	var y := VisualKit._h(x, z) + 0.015
	var stone := MeshInstance3D.new()
	stone.mesh = CraftMeshes.stepping_stone(0.4 + fmod(abs(seed), 1.0) * 0.14, seed)
	stone.material_override = VisualKit.character_material(ForestsPalette.STONE, ForestsPalette.STONE_MOSS)
	stone.position = Vector3(x, y, z)
	stone.rotation_degrees.y = seed * 17.0
	_gen().add_child(stone)


func _make_water() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(8, -0.04, -6)
	_gen().add_child(pond)

	var bed := MeshInstance3D.new()
	var bed_m := CylinderMesh.new()
	bed_m.top_radius = 4.55
	bed_m.bottom_radius = 4.55
	bed_m.height = 0.08
	bed_m.radial_segments = 56
	bed.mesh = bed_m
	bed.material_override = VisualKit.character_material(Color(0.3, 0.4, 0.34), Color(0.18, 0.26, 0.2))
	bed.position.y = -0.05
	pond.add_child(bed)

	var water := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.35
	cyl.bottom_radius = 4.35
	cyl.height = 0.16
	cyl.radial_segments = 56
	water.mesh = cyl
	water.material_override = VisualKit.water_material()
	water.position.y = 0.1
	pond.add_child(water)

	for i in 22:
		var ang := i / 22.0 * TAU
		var r := 4.5 + randf_range(-0.12, 0.5)
		var rock := MeshInstance3D.new()
		rock.mesh = CraftMeshes.rock(14.0 + i * 2.9, randf_range(0.28, 0.56))
		rock.material_override = VisualKit.character_material(
			Color(0.52, 0.5, 0.46).lerp(ForestsPalette.STONE_MOSS, randf()),
			Color(0.32, 0.34, 0.3)
		)
		rock.position = Vector3(cos(ang) * r, 0.04, sin(ang) * r)
		rock.rotation_degrees = Vector3(randf_range(-16, 16), randf() * 360.0, randf_range(-12, 12))
		rock.scale = Vector3(randf_range(0.95, 1.4), randf_range(0.4, 0.7), randf_range(0.95, 1.35))
		pond.add_child(rock)


func _make_cottage() -> void:
	var home := NatureFactory.cottage()
	home.position = Vector3(-6.0, VisualKit._h(-6.0, 4.0), 4.0)
	home.rotation_degrees.y = 18.0
	_gen().add_child(home)
	# soft ground shadow under cottage
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.4
	cm.bottom_radius = 2.4
	cm.height = 0.02
	disc.mesh = cm
	var m := _mat(Color(0.1, 0.14, 0.08, 0.28), 1.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = m
	disc.position = home.position + Vector3(0, 0.02, 0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gen().add_child(disc)


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020
	for i in 52:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.8:
			continue
		if p.distance_to(Vector3(-6, 0, 4)) < 4.5:
			continue
		if p.length() < 3.5:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var is_pine := rng.randf() > 0.72
		var tree: Node3D = NatureFactory.pine_tree(rng) if is_pine else NatureFactory.deciduous_tree(rng)
		_wrap_interact_tree(tree, p, rng, is_pine)

	for i in 10:
		var ang := i / 10.0 * TAU + 0.12
		var p := Vector3(cos(ang) * 24.5, -0.08, sin(ang) * 24.5)
		var tree := NatureFactory.deciduous_tree(rng, true)
		tree.position = p
		_gen().add_child(tree)


func _wrap_interact_tree(tree: Node3D, pos: Vector3, rng: RandomNumberGenerator, is_pine: bool) -> void:
	var body := Interactable.new()
	body.interact_id = ("pine_" if is_pine else "tree_") + "%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "青葉の針葉樹" if is_pine else "葉ずれの木"
	body.examine_text = "針葉の匂いが澄んでいる。" if is_pine else "樹皮に手を当てると、森の鼓動がする。"
	body.item_id = "pine_needle" if is_pine else "softwood"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos
	var h: float = float(tree.get_meta("tree_height")) if tree.has_meta("tree_height") else 2.8
	var kids := tree.get_children()
	for c in kids:
		tree.remove_child(c)
		body.add_child(c)
	tree.free()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.85
	shape.height = h + 1.4
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)
	_gen().add_child(body)


func _scatter_flowers_bushes_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var petals: Array = ForestsPalette.petals()

	for i in 56:
		var p := _rand_point(rng, 2.2, 5.0)
		if p.distance_to(Vector3(-6, 0, 4)) < 3.2:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var body := Interactable.new()
		body.interact_id = "flower_%d_%d" % [int(p.x * 10), int(p.z * 10)]
		body.display_name = "ひだまり草"
		body.examine_text = "花弁が光をすくっている。"
		body.item_id = "sunpetal"
		body.item_amount = 1
		body.position = p
		body.add_child(NatureFactory.flower(rng, petals[rng.randi_range(0, petals.size() - 1)]))
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		col.shape = shape
		col.position.y = 0.25
		body.add_child(col)
		_gen().add_child(body)

	for i in 20:
		var p := _rand_point(rng, 2.5, 4.0)
		if p.distance_to(Vector3(-6, 0, 4)) < 3.5:
			continue
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
		bush.material_override = VisualKit.foliage_material(bc, bc.darkened(0.32))
		body.add_child(bush)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.65
		col.shape = shape
		col.position.y = 0.3
		body.add_child(col)
		_gen().add_child(body)

	for i in 20:
		var p := _rand_point(rng, 3.0, 5.5)
		if p.distance_to(Vector3(-6, 0, 4)) < 3.0:
			continue
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
		rock.material_override = VisualKit.character_material(
			Color(0.5, 0.5, 0.48).lerp(ForestsPalette.STONE_MOSS, rng.randf()),
			Color(0.3, 0.32, 0.28)
		)
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


func _make_spawn_garden() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var cols: Array = ForestsPalette.petals()
	for i in 18:
		var ang := i / 18.0 * TAU
		var r := 4.15 + (i % 3) * 0.32
		var p := Vector3(cos(ang) * r, 0, sin(ang) * r + 2.5)
		p.y = VisualKit._h(p.x, p.z)
		var f := NatureFactory.flower(rng, cols[i % cols.size()])
		f.position = p
		f.scale = Vector3.ONE * rng.randf_range(1.05, 1.4)
		_gen().add_child(f)


func _scatter_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var gmat := VisualKit.grass_material()
	for i in 380:
		var p := _rand_point(rng, 1.6, 4.6)
		p.y = VisualKit._h(p.x, p.z)
		var grass := MeshInstance3D.new()
		grass.mesh = CraftMeshes.grass_clump(rng.randi_range(8, 13), rng.randf_range(0.95, 1.6), float(i) * 1.7)
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
	var fill := OmniLight3D.new()
	fill.light_color = ForestsPalette.FILL_COOL
	fill.light_energy = 1.1
	fill.omni_range = 50.0
	fill.position = Vector3(-10, 13, 14)
	_gen().add_child(fill)

	var warm := OmniLight3D.new()
	warm.light_color = ForestsPalette.FILL_WARM
	warm.light_energy = 1.0
	warm.omni_range = 36.0
	warm.position = Vector3(12, 7.5, -4)
	_gen().add_child(warm)

	var ground := OmniLight3D.new()
	ground.light_color = ForestsPalette.BOUNCE_GREEN
	ground.light_energy = 0.6
	ground.omni_range = 32.0
	ground.position = Vector3(0, 1.5, 2)
	_gen().add_child(ground)

	var pond_l := OmniLight3D.new()
	pond_l.light_color = Color(0.72, 0.94, 0.96)
	pond_l.light_energy = 0.75
	pond_l.omni_range = 11.0
	pond_l.position = Vector3(8, 1.6, -6)
	_gen().add_child(pond_l)

	# cottage warm window glow
	var home_l := OmniLight3D.new()
	home_l.light_color = Color(1.0, 0.85, 0.55)
	home_l.light_energy = 0.85
	home_l.omni_range = 8.0
	home_l.position = Vector3(-6.0, 1.4, 5.2)
	_gen().add_child(home_l)


func _add_ambience() -> void:
	var pollen := GPUParticles3D.new()
	pollen.amount = 80
	pollen.lifetime = 11.0
	pollen.preprocess = 4.0
	pollen.visibility_aabb = AABB(Vector3(-22, 0, -22), Vector3(44, 14, 44))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 2.8, 16)
	mat.direction = Vector3(0.12, 0.55, 0.08)
	mat.spread = 55.0
	mat.initial_velocity_min = 0.08
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3(0, 0.01, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(1.0, 0.95, 0.75, 0.9)
	pollen.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.5
	pollen.draw_pass_1 = draw
	pollen.position = Vector3(0, 2.8, 0)
	_gen().add_child(pollen)

	var motes := GPUParticles3D.new()
	motes.amount = 40
	motes.lifetime = 8.0
	motes.preprocess = 2.0
	motes.visibility_aabb = AABB(Vector3(-18, 0, -18), Vector3(36, 12, 36))
	var mat2 := ParticleProcessMaterial.new()
	mat2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat2.emission_box_extents = Vector3(12, 2, 12)
	mat2.direction = Vector3(-0.1, 0.4, 0.15)
	mat2.spread = 40.0
	mat2.initial_velocity_min = 0.05
	mat2.initial_velocity_max = 0.18
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
