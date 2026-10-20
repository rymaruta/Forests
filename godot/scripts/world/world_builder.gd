extends Node3D
class_name WorldBuilder
## スタイライズド森のビジュアル構築


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_path()
	_make_water()
	_scatter_trees_and_props()
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


func _make_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var mesh := MeshInstance3D.new()
	mesh.mesh = VisualKit.make_height_terrain(52.0, 56)
	mesh.material_override = VisualKit.terrain_material()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	ground.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(52, 2.0, 52)
	col.shape = shape
	col.position.y = -0.9
	ground.add_child(col)
	_gen().add_child(ground)


func _make_path() -> void:
	for a in 20:
		var ang := a / 20.0 * TAU
		var p := Vector3(cos(ang) * 3.4, 0.04, sin(ang) * 3.4 + 2.6)
		var dirt := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.15, 0.04, 0.65)
		dirt.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.58, 0.44, 0.30)
		mat.roughness = 0.95
		dirt.material_override = mat
		_gen().add_child(dirt)
		dirt.global_position = p
		dirt.look_at(Vector3(0, 0.04, 2.6), Vector3.UP)


func _make_water() -> void:
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.position = Vector3(8, -0.05, -6)
	_gen().add_child(pond)

	var shore := MeshInstance3D.new()
	var shore_m := TorusMesh.new()
	shore_m.inner_radius = 4.1
	shore_m.outer_radius = 5.0
	shore_m.rings = 24
	shore_m.ring_segments = 12
	shore.mesh = shore_m
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.72, 0.64, 0.46)
	smat.roughness = 0.9
	shore.material_override = smat
	shore.position.y = 0.08
	shore.scale = Vector3(1, 0.25, 1)
	pond.add_child(shore)

	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 4.35
	wm.bottom_radius = 4.35
	wm.height = 0.2
	wm.radial_segments = 32
	water.mesh = wm
	water.material_override = VisualKit.water_material()
	water.position.y = 0.12
	pond.add_child(water)

	# lily pads
	for i in 7:
		var pad := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = randf_range(0.25, 0.45)
		cyl.bottom_radius = cyl.top_radius
		cyl.height = 0.03
		pad.mesh = cyl
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.28, 0.52, 0.32)
		pm.roughness = 0.7
		pad.material_override = pm
		var ang := i / 7.0 * TAU + 0.4
		var r := randf_range(1.0, 3.2)
		pad.position = Vector3(cos(ang) * r, 0.24, sin(ang) * r)
		pond.add_child(pad)

	for i in 12:
		var ang := i / 12.0 * TAU
		var r := 4.7 + randf_range(-0.2, 0.4)
		_add_rock(Vector3(8 + cos(ang) * r, 0, -6 + sin(ang) * r), "river_pebble", "川辺の石", true)


func _scatter_trees_and_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020

	for i in 38:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.8:
			continue
		if p.length() < 3.2:
			continue
		# lift with terrain height
		p.y = VisualKit._h(p.x, p.z)
		if rng.randf() > 0.72:
			_add_pine(p, rng)
		else:
			_add_deciduous(p, rng)

	for i in 28:
		var p := Vector3(rng.randf_range(-15, 15), 0, rng.randf_range(-15, 15))
		if p.length() < 2.4:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < 5.0:
			continue
		p.y = VisualKit._h(p.x, p.z)
		_add_flower(p, rng)

	for i in 14:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.distance_to(Vector3(8, 0, -6)) < 5.2:
			continue
		p.y = VisualKit._h(p.x, p.z)
		_add_rock(p, "river_pebble", "苔むした岩", rng.randf() > 0.4)

	for i in 12:
		var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		p.y = VisualKit._h(p.x, p.z)
		_add_moss_clump(p)

	# distant soft hills
	for i in 6:
		var hill := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = rng.randf_range(5.0, 8.5)
		s.height = s.radius * 0.5
		hill.mesh = s
		hill.material_override = VisualKit.foliage_material(
			Color(0.40, 0.55, 0.36), Color(0.28, 0.40, 0.26)
		)
		var ang := i / 6.0 * TAU + 0.3
		hill.position = Vector3(cos(ang) * 30.0, -1.5, sin(ang) * 30.0)
		_gen().add_child(hill)


func _scatter_grass() -> void:
	var blade := VisualKit.make_grass_blade_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = 420

	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var i := 0
	while i < mm.instance_count:
		var x := rng.randf_range(-18, 18)
		var z := rng.randf_range(-18, 18)
		var p := Vector3(x, 0, z)
		if p.length() < 2.0:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < 5.0:
			continue
		var y := VisualKit._h(x, z)
		var xf := Transform3D.IDENTITY
		xf = xf.scaled(Vector3(
			rng.randf_range(0.7, 1.3),
			rng.randf_range(0.7, 1.45),
			rng.randf_range(0.7, 1.3)
		))
		xf = xf.rotated(Vector3.UP, rng.randf() * TAU)
		xf.origin = Vector3(x, y, z)
		mm.set_instance_transform(i, xf)
		i += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassField"
	mmi.multimesh = mm
	mmi.material_override = VisualKit.grass_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gen().add_child(mmi)


func _add_deciduous(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "tree_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "葉ずれの木"
	body.examine_text = "樹皮が温かい。折れた枝が採れそうだ。"
	body.item_id = "softwood"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos

	var trunk_h := rng.randf_range(1.8, 2.8)
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.30
	cyl.height = trunk_h
	cyl.radial_segments = 10
	trunk.mesh = cyl
	trunk.material_override = VisualKit.bark_material(
		Color(0.40, 0.26, 0.16).lerp(Color(0.48, 0.32, 0.20), rng.randf())
	)
	trunk.position.y = trunk_h * 0.5
	trunk.rotation_degrees.z = rng.randf_range(-4, 4)
	body.add_child(trunk)

	var leaf_col := Color(0.34, 0.58, 0.32).lerp(Color(0.48, 0.66, 0.34), rng.randf())
	var dark := leaf_col.darkened(0.28)
	var mat := VisualKit.foliage_material(leaf_col, dark)

	# layered soft canopy (flattened spheres + offsets)
	var layers := [
		Vector3(0.0, trunk_h + 0.55, 0.0),
		Vector3(0.35, trunk_h + 0.25, 0.15),
		Vector3(-0.3, trunk_h + 0.3, -0.2),
		Vector3(0.1, trunk_h + 0.9, -0.15),
		Vector3(-0.15, trunk_h + 0.75, 0.25),
	]
	for li in layers.size():
		var leaves := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.65, 1.05) * (1.0 if li < 3 else 0.75)
		sphere.height = sphere.radius * rng.randf_range(1.3, 1.7)
		sphere.radial_segments = 12
		sphere.rings = 8
		leaves.mesh = sphere
		leaves.material_override = mat
		leaves.position = layers[li]
		leaves.scale = Vector3(
			rng.randf_range(1.0, 1.35),
			rng.randf_range(0.7, 0.95),
			rng.randf_range(1.0, 1.35)
		)
		body.add_child(leaves)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = trunk_h + 1.4
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)
	_gen().add_child(body)


func _add_pine(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "pine_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "青葉の針葉樹"
	body.examine_text = "香りが高い。青葉が採れそうだ。"
	body.item_id = "pine_needle"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos

	var trunk_h := rng.randf_range(2.2, 3.2)
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.22
	cyl.height = trunk_h
	trunk.mesh = cyl
	trunk.material_override = VisualKit.bark_material(Color(0.35, 0.24, 0.18))
	trunk.position.y = trunk_h * 0.5
	body.add_child(trunk)

	var mat := VisualKit.foliage_material(Color(0.22, 0.42, 0.30), Color(0.12, 0.28, 0.18))
	for k in 4:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var r := 1.1 - k * 0.18
		cm.top_radius = 0.02
		cm.bottom_radius = r
		cm.height = 0.85
		cone.mesh = cm
		cone.material_override = mat
		cone.position.y = 1.0 + k * 0.55
		body.add_child(cone)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = trunk_h + 1.0
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
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.03
	cyl.height = 0.45
	stem.mesh = cyl
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.25, 0.5, 0.28)
	stem.material_override = sm
	stem.position.y = 0.22
	body.add_child(stem)

	var petal_cols := [
		Color(0.98, 0.78, 0.38),
		Color(0.95, 0.58, 0.68),
		Color(0.88, 0.82, 0.98),
		Color(1.0, 0.92, 0.62),
		Color(0.75, 0.88, 0.98),
	]
	var base_col: Color = petal_cols[rng.randi_range(0, petal_cols.size() - 1)]
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = base_col
	pmat.roughness = 0.45
	pmat.emission_enabled = true
	pmat.emission = base_col
	pmat.emission_energy_multiplier = 0.15

	for p in 6:
		var petal := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.1
		petal.mesh = sphere
		petal.material_override = pmat
		var ang := p / 6.0 * TAU
		petal.position = Vector3(cos(ang) * 0.11, 0.48, sin(ang) * 0.11)
		petal.scale = Vector3(1.2, 0.4, 0.75)
		body.add_child(petal)

	var center := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.07
	center.mesh = cs
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.95, 0.82, 0.3)
	center.material_override = cm
	center.position.y = 0.49
	body.add_child(center)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	col.position.y = 0.25
	body.add_child(col)
	_gen().add_child(body)


func _add_rock(pos: Vector3, item: String, label: String, with_moss: bool = false) -> void:
	var body := Interactable.new()
	body.interact_id = "rock_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = label
	body.examine_text = "手のひらに収まる石。ポケットに入れられそうだ。"
	body.item_id = item
	body.item_amount = 1
	body.position = pos

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = randf_range(0.3, 0.6)
	sphere.height = sphere.radius * randf_range(0.95, 1.35)
	sphere.radial_segments = 10
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.54, 0.56).lerp(Color(0.46, 0.48, 0.42), randf())
	mat.roughness = 0.82
	mesh.material_override = mat
	mesh.position.y = sphere.height * 0.25
	mesh.scale = Vector3(randf_range(0.95, 1.45), randf_range(0.5, 0.8), randf_range(0.95, 1.35))
	mesh.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), randf_range(-12, 12))
	body.add_child(mesh)

	if with_moss:
		var moss := MeshInstance3D.new()
		var ms := SphereMesh.new()
		ms.radius = 0.14
		moss.mesh = ms
		moss.material_override = VisualKit.foliage_material(Color(0.34, 0.52, 0.32))
		moss.position = mesh.position + Vector3(0.06, 0.1, 0.02)
		moss.scale = Vector3(1.5, 0.35, 1.2)
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

	var mat := VisualKit.foliage_material(Color(0.32, 0.50, 0.34), Color(0.2, 0.36, 0.24))
	for i in 4:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.26 + i * 0.04
		mesh.mesh = sphere
		mesh.material_override = mat
		mesh.position = Vector3(randf_range(-0.18, 0.18), 0.08, randf_range(-0.18, 0.18))
		mesh.scale = Vector3(1.35, 0.38, 1.15)
		body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	col.position.y = 0.1
	body.add_child(col)
	_gen().add_child(body)


func _add_lights() -> void:
	# 影を溶かして柔らかくする補助光
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.75, 0.88, 1.0)
	fill.light_energy = 0.85
	fill.omni_range = 40.0
	fill.position = Vector3(-8, 10, 12)
	_gen().add_child(fill)

	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.86, 0.65)
	warm.light_energy = 0.7
	warm.omni_range = 28.0
	warm.position = Vector3(12, 6, -2)
	_gen().add_child(warm)

	var rim := OmniLight3D.new()
	rim.light_color = Color(0.85, 0.95, 0.8)
	rim.light_energy = 0.45
	rim.omni_range = 24.0
	rim.position = Vector3(0, 4, -12)
	_gen().add_child(rim)

	var ground := OmniLight3D.new()
	ground.light_color = Color(0.55, 0.7, 0.45)
	ground.light_energy = 0.35
	ground.omni_range = 30.0
	ground.position = Vector3(0, 1.5, 0)
	_gen().add_child(ground)


func _add_ambience() -> void:
	var pollen := GPUParticles3D.new()
	pollen.name = "Pollen"
	pollen.amount = 40
	pollen.lifetime = 8.0
	pollen.preprocess = 2.0
	pollen.visibility_aabb = AABB(Vector3(-20, 0, -20), Vector3(40, 12, 40))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 2, 16)
	mat.direction = Vector3(0.2, 0.4, 0.1)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.45
	mat.gravity = Vector3(0, 0.02, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.09
	mat.color = Color(1.0, 0.95, 0.7, 0.75)
	pollen.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.5
	draw.height = 1.0
	pollen.draw_pass_1 = draw
	pollen.position = Vector3(0, 2.5, 0)
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
