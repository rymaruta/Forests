extends Node3D
class_name WorldBuilder
## Kenney Nature Kit (CC0) + スタイライズド地形/水


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_path()
	_make_water()
	_scatter_nature()
	_scatter_grass_models()
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
	for a in 18:
		var ang := a / 18.0 * TAU
		var p := Vector3(cos(ang) * 3.5, VisualKit._h(cos(ang) * 3.5, sin(ang) * 3.5 + 2.5) + 0.01, sin(ang) * 3.5 + 2.5)
		var tile := AssetLibrary.instance("path_stone", 1.05, rad_to_deg(ang) + 90.0)
		_gen().add_child(tile)
		tile.global_position = p


func _make_water() -> void:
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.position = Vector3(8, -0.08, -6)
	_gen().add_child(pond)

	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 4.4
	wm.bottom_radius = 4.4
	wm.height = 0.22
	wm.radial_segments = 36
	water.mesh = wm
	water.material_override = VisualKit.water_material()
	water.position.y = 0.14
	pond.add_child(water)

	# shore rocks from Kenney
	for i in 14:
		var ang := i / 14.0 * TAU
		var r := 4.6 + randf_range(-0.15, 0.45)
		var names: Array = AssetLibrary.rocks_small()
		var n: String = names[i % names.size()]
		var rock := AssetLibrary.instance(n, randf_range(0.9, 1.4), randf() * 360.0)
		pond.add_child(rock)
		rock.position = Vector3(cos(ang) * r, 0.05, sin(ang) * r)

	# a few larger rocks
	for i in 4:
		var ang := i / 4.0 * TAU + 0.4
		var rock := AssetLibrary.instance(AssetLibrary.rocks_large()[i % 2], randf_range(0.7, 1.0), randf() * 360.0)
		pond.add_child(rock)
		rock.position = Vector3(cos(ang) * 5.2, 0.02, sin(ang) * 5.2)


func _scatter_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020

	# Trees
	for i in 42:
		var p := Vector3(rng.randf_range(-17, 17), 0, rng.randf_range(-17, 17))
		if p.distance_to(Vector3(8, 0, -6)) < 6.8:
			continue
		if p.length() < 3.4:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var pine := rng.randf() > 0.62
		var list: Array = AssetLibrary.trees_pine() if pine else AssetLibrary.trees_deciduous()
		var name: String = list[rng.randi_range(0, list.size() - 1)]
		var scale := rng.randf_range(1.6, 2.6) if pine else rng.randf_range(1.8, 2.9)
		_add_interactable_model(
			p,
			name,
			scale,
			rng.randf() * 360.0,
			"pine_%d_%d" % [int(p.x * 10), int(p.z * 10)] if pine else "tree_%d_%d" % [int(p.x * 10), int(p.z * 10)],
			"青葉の針葉樹" if pine else "葉ずれの木",
			"香りが高い。青葉が採れそうだ。" if pine else "樹皮が温かい。折れた枝が採れそうだ。",
			"pine_needle" if pine else "softwood",
			rng.randi_range(1, 2),
			1.1
		)

	# Flowers
	for i in 36:
		var p := Vector3(rng.randf_range(-15, 15), 0, rng.randf_range(-15, 15))
		if p.length() < 2.2:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < 5.0:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var fname: String = AssetLibrary.flowers()[rng.randi_range(0, AssetLibrary.flowers().size() - 1)]
		_add_interactable_model(
			p, fname, rng.randf_range(1.2, 1.8), rng.randf() * 360.0,
			"flower_%d_%d" % [int(p.x * 10), int(p.z * 10)],
			"ひだまり草", "小さな花が揺れている。花弁をそっと摘めそうだ。",
			"sunpetal", 1, 0.45
		)

	# Bushes (moss gather)
	for i in 16:
		var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		if p.length() < 2.5:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var bname: String = AssetLibrary.bushes()[rng.randi_range(0, AssetLibrary.bushes().size() - 1)]
		_add_interactable_model(
			p, bname, rng.randf_range(1.3, 2.0), rng.randf() * 360.0,
			"moss_%d_%d" % [int(p.x * 10), int(p.z * 10)],
			"こけの茂み", "湿った香り。こけ房が採れそうだ。",
			"moss_tuft", 1, 0.7
		)

	# Rocks
	for i in 18:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.distance_to(Vector3(8, 0, -6)) < 5.5:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var rname: String = AssetLibrary.rocks_small()[rng.randi_range(0, AssetLibrary.rocks_small().size() - 1)]
		if rng.randf() > 0.7:
			rname = AssetLibrary.rocks_large()[rng.randi_range(0, 1)]
		_add_interactable_model(
			p, rname, rng.randf_range(1.0, 1.7), rng.randf() * 360.0,
			"rock_%d_%d" % [int(p.x * 10), int(p.z * 10)],
			"苔むした岩", "手のひらに収まる石。ポケットに入れられそうだ。",
			"river_pebble", 1, 0.55
		)

	# Decorative logs
	for i in 6:
		var p := Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
		if p.length() < 4.0:
			continue
		p.y = VisualKit._h(p.x, p.z)
		var logn := AssetLibrary.instance("log" if rng.randf() > 0.4 else "log_large", rng.randf_range(1.0, 1.5), rng.randf() * 360.0)
		_gen().add_child(logn)
		logn.global_position = p

	# Distant hill silhouettes using large dark trees as backdrop
	for i in 10:
		var ang := i / 10.0 * TAU
		var p := Vector3(cos(ang) * 24.0, -0.2, sin(ang) * 24.0)
		var t := AssetLibrary.instance("tree_tall", rng.randf_range(3.5, 5.0), rng.randf() * 360.0)
		_gen().add_child(t)
		t.global_position = p


func _scatter_grass_models() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 160:
		var x := rng.randf_range(-18, 18)
		var z := rng.randf_range(-18, 18)
		var p := Vector3(x, 0, z)
		if p.length() < 2.0:
			continue
		if p.distance_to(Vector3(8, 0, -6)) < 5.0:
			continue
		p.y = VisualKit._h(x, z)
		var gname: String = AssetLibrary.grass_clumps()[rng.randi_range(0, AssetLibrary.grass_clumps().size() - 1)]
		var g := AssetLibrary.instance(gname, rng.randf_range(1.0, 1.8), rng.randf() * 360.0)
		_gen().add_child(g)
		g.global_position = p


func _add_interactable_model(
	pos: Vector3,
	asset_name: String,
	scale: float,
	yaw: float,
	id: String,
	display: String,
	examine: String,
	item: String,
	amount: int,
	col_radius: float
) -> void:
	var body := Interactable.new()
	body.interact_id = id
	body.display_name = display
	body.examine_text = examine
	body.item_id = item
	body.item_amount = amount
	body.position = pos

	var model := AssetLibrary.instance(asset_name, scale, yaw)
	body.add_child(model)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = col_radius * maxf(scale * 0.35, 0.8)
	col.shape = shape
	col.position.y = shape.radius * 0.6
	body.add_child(col)
	_gen().add_child(body)


func _add_lights() -> void:
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
	pollen.amount = 48
	pollen.lifetime = 9.0
	pollen.preprocess = 2.0
	pollen.visibility_aabb = AABB(Vector3(-22, 0, -22), Vector3(44, 14, 44))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 2, 16)
	mat.direction = Vector3(0.2, 0.45, 0.1)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.12
	mat.initial_velocity_max = 0.4
	mat.gravity = Vector3(0, 0.015, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.1
	mat.color = Color(1.0, 0.95, 0.7, 0.8)
	pollen.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.5
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
