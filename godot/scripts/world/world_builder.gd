extends Node3D
class_name WorldBuilder
## 小さな森マップを手続き的に配置（自作プリミティブのみ）


func build() -> void:
	_clear_generated()
	_make_ground()
	_make_water()
	_scatter_nature()
	_make_boundary()


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
	var plane := PlaneMesh.new()
	plane.size = Vector2(48, 48)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.55, 0.34)
	mat.roughness = 0.95
	mesh.material_override = mat
	ground.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(48, 0.2, 48)
	col.shape = shape
	col.position.y = -0.1
	ground.add_child(col)
	_gen().add_child(ground)

	# 柔らかい起伏用の苔パッチ
	for i in 18:
		var patch := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(1.5, 3.5), 0.08, randf_range(1.5, 3.5))
		patch.mesh = box
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.30, 0.48, 0.32)
		patch.material_override = pm
		patch.position = Vector3(randf_range(-18, 18), 0.04, randf_range(-18, 18))
		_gen().add_child(patch)


func _make_water() -> void:
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 6)
	water.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.48, 0.55, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.2
	water.material_override = mat
	water.position = Vector3(8, 0.05, -6)
	_gen().add_child(water)

	# 水辺の石
	for i in 6:
		_add_rock(Vector3(8 + randf_range(-5, 5), 0, -6 + randf_range(-3, 3)), "river_pebble", "川辺の石")


func _scatter_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261020

	for i in 28:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		if p.distance_to(Vector3(8, 0, -6)) < 6.0:
			continue
		if p.length() < 2.5:
			continue
		_add_tree(p, rng)

	for i in 16:
		var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		if p.length() < 2.0:
			continue
		_add_flower(p, rng)

	for i in 10:
		var p := Vector3(rng.randf_range(-15, 15), 0, rng.randf_range(-15, 15))
		_add_rock(p, "river_pebble", "苔むした岩")

	for i in 8:
		var p := Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
		_add_moss_clump(p)


func _add_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var body := Interactable.new()
	body.interact_id = "tree_%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	body.display_name = "葉ずれの木"
	body.examine_text = "樹皮が温かい。折れた枝が採れそうだ。"
	body.item_id = "softwood"
	body.item_amount = rng.randi_range(1, 2)
	body.position = pos

	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.28
	cyl.height = rng.randf_range(1.4, 2.2)
	trunk.mesh = cyl
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.36, 0.24, 0.16)
	trunk.material_override = tmat
	trunk.position.y = cyl.height * 0.5
	body.add_child(trunk)

	var leaves := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = rng.randf_range(0.7, 1.1)
	leaves.mesh = sphere
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.28, 0.48, 0.30)
	leaves.material_override = lmat
	leaves.position.y = cyl.height + sphere.radius * 0.45
	body.add_child(leaves)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.55
	shape.height = cyl.height + 1.0
	col.shape = shape
	col.position.y = shape.height * 0.4
	body.add_child(col)

	# 葉の下に青葉も採れる別対象は花で賄う
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
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.04
	cyl.height = 0.35
	stem.mesh = cyl
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.25, 0.45, 0.22)
	stem.material_override = sm
	stem.position.y = 0.18
	body.add_child(stem)

	var petal := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	petal.mesh = sphere
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.92, 0.72, 0.35) if rng.randf() > 0.4 else Color(0.85, 0.55, 0.62)
	petal.material_override = pm
	petal.position.y = 0.4
	body.add_child(petal)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.2
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
	var box := BoxMesh.new()
	box.size = Vector3(randf_range(0.4, 0.9), randf_range(0.25, 0.5), randf_range(0.4, 0.8))
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.54, 0.56)
	mat.roughness = 0.9
	mesh.material_override = mat
	mesh.position.y = box.size.y * 0.5
	mesh.rotation_degrees.y = randf_range(0, 360)
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position.y = box.size.y * 0.5
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

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.35
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.48, 0.32)
	mesh.material_override = mat
	mesh.position.y = 0.12
	mesh.scale = Vector3(1.2, 0.45, 1.0)
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	col.position.y = 0.1
	body.add_child(col)
	_gen().add_child(body)


func _make_boundary() -> void:
	# 見えない壁
	for dir in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		if abs(dir.x) > 0:
			shape.size = Vector3(1, 6, 50)
			wall.position = dir * 24.5
		else:
			shape.size = Vector3(50, 6, 1)
			wall.position = dir * 24.5
		col.shape = shape
		col.position.y = 3
		wall.add_child(col)
		_gen().add_child(wall)
