extends CharacterBody3D
class_name PlayerController
## Forests 旅人。読みやすいシルエットと優しい比率で手組み。

const SPEED := 4.2
const ACCEL := 12.0
const GRAVITY := 18.0

var move_input: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var _bob_t: float = 0.0

@onready var mesh_root: Node3D = $MeshRoot


func _ready() -> void:
	_build_visual()
	floor_snap_length = 0.25


func _mat(c: Color, rough: float = 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _build_visual() -> void:
	for c in mesh_root.get_children():
		c.queue_free()

	# 靴（少し丸くてかわいい）
	for side in [-1.0, 1.0]:
		var boot := MeshInstance3D.new()
		boot.mesh = CraftMeshes.uv_sphere(0.095, 6, 8, 0.12, side + 2.0, 0.7)
		boot.material_override = _mat(Color(0.32, 0.2, 0.14), 0.88)
		boot.position = Vector3(0.1 * side, 0.07, 0.05)
		boot.scale = Vector3(1.15, 0.75, 1.4)
		mesh_root.add_child(boot)

	# 脚（短め＝ちび比率）
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.mesh = CraftMeshes.trunk(0.26, 0.075, 0.065, 8)
		leg.material_override = _mat(Color(0.22, 0.38, 0.34))
		leg.position = Vector3(0.095 * side, 0.08, 0)
		mesh_root.add_child(leg)

	# 胴（ベスト＋シャツ感）
	var torso := MeshInstance3D.new()
	torso.mesh = CraftMeshes.trunk(0.48, 0.2, 0.175, 12)
	torso.material_override = _mat(Color(0.28, 0.58, 0.52))
	torso.position.y = 0.32
	mesh_root.add_child(torso)

	# ベルト
	var belt := MeshInstance3D.new()
	var belt_m := CylinderMesh.new()
	belt_m.top_radius = 0.195
	belt_m.bottom_radius = 0.195
	belt_m.height = 0.04
	belt.mesh = belt_m
	belt.material_override = _mat(Color(0.42, 0.26, 0.14), 0.7)
	belt.position.y = 0.36
	mesh_root.add_child(belt)

	# マント
	var cloak := MeshInstance3D.new()
	cloak.mesh = CraftMeshes.cloak_mesh(0.48, 0.58)
	cloak.material_override = _mat(Color(0.16, 0.32, 0.28), 0.9)
	cloak.position = Vector3(0, 0.78, -0.02)
	mesh_root.add_child(cloak)

	# 腕
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = CraftMeshes.trunk(0.3, 0.055, 0.045, 8, 0.015 * side)
		arm.material_override = _mat(Color(0.26, 0.52, 0.46))
		arm.position = Vector3(0.23 * side, 0.68, 0)
		arm.rotation_degrees.z = -22.0 * side
		mesh_root.add_child(arm)
		# 手
		var hand := MeshInstance3D.new()
		hand.mesh = CraftMeshes.uv_sphere(0.055, 5, 6)
		hand.material_override = _mat(Color(0.94, 0.82, 0.7), 0.5)
		hand.position = Vector3(0.34 * side, 0.42, 0.02)
		mesh_root.add_child(hand)

	# 頭（大きめ比率）
	var head := MeshInstance3D.new()
	head.mesh = CraftMeshes.uv_sphere(0.22, 9, 12, 0.04, 3.0, 1.05)
	head.material_override = _mat(Color(0.96, 0.86, 0.74), 0.5)
	head.position.y = 1.0
	mesh_root.add_child(head)

	# 髪（前髪＋後髪）
	var hair := MeshInstance3D.new()
	hair.mesh = CraftMeshes.uv_sphere(0.235, 8, 10, 0.16, 8.0, 0.78)
	hair.material_override = _mat(Color(0.28, 0.17, 0.1), 0.85)
	hair.position = Vector3(0, 1.08, -0.03)
	mesh_root.add_child(hair)

	var bang := MeshInstance3D.new()
	bang.mesh = CraftMeshes.uv_sphere(0.12, 6, 8, 0.2, 4.0, 0.55)
	bang.material_override = _mat(Color(0.28, 0.17, 0.1), 0.85)
	bang.position = Vector3(0, 1.08, 0.14)
	bang.scale = Vector3(1.4, 0.7, 0.6)
	mesh_root.add_child(bang)

	# 目（大きくて読みやすい）
	for side in [-1.0, 1.0]:
		var white := MeshInstance3D.new()
		white.mesh = CraftMeshes.uv_sphere(0.045, 5, 6, 0.0, 1.0, 0.85)
		white.material_override = _mat(Color(0.98, 0.98, 0.96), 0.35)
		white.position = Vector3(0.07 * side, 1.0, 0.18)
		mesh_root.add_child(white)
		var iris := MeshInstance3D.new()
		iris.mesh = CraftMeshes.uv_sphere(0.028, 4, 5)
		iris.material_override = _mat(Color(0.22, 0.32, 0.28), 0.35)
		iris.position = Vector3(0.07 * side, 0.995, 0.21)
		mesh_root.add_child(iris)
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.01, 3, 4)
		var sm := _mat(Color(1, 1, 1), 0.2)
		sm.emission_enabled = true
		sm.emission = Color(1, 1, 1)
		sm.emission_energy_multiplier = 0.4
		shine.material_override = sm
		shine.position = Vector3(0.078 * side, 1.01, 0.225)
		mesh_root.add_child(shine)

	# ほっぺ
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.03, 4, 5, 0.0, 1.0, 0.7)
		var cm := _mat(Color(0.98, 0.7, 0.68), 0.6)
		cm.emission_enabled = true
		cm.emission = Color(0.95, 0.55, 0.5)
		cm.emission_energy_multiplier = 0.15
		cheek.material_override = cm
		cheek.position = Vector3(0.14 * side, 0.94, 0.15)
		mesh_root.add_child(cheek)

	# 口（小さな弧）
	var mouth := MeshInstance3D.new()
	mouth.mesh = CraftMeshes.uv_sphere(0.018, 4, 5, 0.0, 1.0, 0.4)
	mouth.material_override = _mat(Color(0.75, 0.4, 0.42), 0.5)
	mouth.position = Vector3(0, 0.9, 0.2)
	mouth.scale = Vector3(1.4, 0.45, 0.6)
	mesh_root.add_child(mouth)

	# 帽子つば
	var brim := MeshInstance3D.new()
	var brim_m := CylinderMesh.new()
	brim_m.top_radius = 0.34
	brim_m.bottom_radius = 0.34
	brim_m.height = 0.03
	brim_m.radial_segments = 20
	brim.mesh = brim_m
	brim.material_override = _mat(Color(0.72, 0.52, 0.28), 0.7)
	brim.position.y = 1.16
	mesh_root.add_child(brim)

	# 帽子本体
	var crown := MeshInstance3D.new()
	crown.mesh = CraftMeshes.trunk(0.18, 0.18, 0.1, 12)
	crown.material_override = _mat(Color(0.68, 0.48, 0.26), 0.72)
	crown.position.y = 1.18
	mesh_root.add_child(crown)

	# 帽子バンド
	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.185
	band_m.bottom_radius = 0.185
	band_m.height = 0.035
	band.mesh = band_m
	band.material_override = _mat(Color(0.55, 0.28, 0.18), 0.65)
	band.position.y = 1.2
	mesh_root.add_child(band)

	# マフラー
	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.09
	torus.outer_radius = 0.17
	torus.rings = 16
	torus.ring_segments = 10
	scarf.mesh = torus
	scarf.material_override = _mat(Color(0.9, 0.52, 0.3), 0.6)
	scarf.position.y = 0.82
	scarf.rotation_degrees.x = 90
	mesh_root.add_child(scarf)

	var tail := MeshInstance3D.new()
	tail.mesh = CraftMeshes.trunk(0.32, 0.055, 0.03, 6, 0.06)
	tail.material_override = _mat(Color(0.9, 0.52, 0.3), 0.6)
	tail.position = Vector3(0.14, 0.62, 0.1)
	tail.rotation_degrees.z = 28
	mesh_root.add_child(tail)

	# 小さく全体スケール（足元基準）
	mesh_root.scale = Vector3(1.05, 1.05, 1.05)


func set_move_input(v: Vector2) -> void:
	move_input = v.limit_length(1.0)


func get_facing_yaw() -> float:
	return yaw


func set_facing_yaw(value: float) -> void:
	yaw = value
	mesh_root.rotation.y = yaw


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if not GameState.is_menu_open:
		var kb := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			kb.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			kb.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			kb.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			kb.y += 1.0
		if kb.length() > 0.01:
			move_input = kb.limit_length(1.0)

	var cam := get_viewport().get_camera_3d()
	var wish := Vector3.ZERO
	if move_input.length() > 0.05 and cam:
		var forward := -cam.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := cam.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		wish = (right * move_input.x + forward * -move_input.y).normalized()
		yaw = atan2(wish.x, wish.z)
		mesh_root.rotation.y = yaw

	var target := wish * SPEED * GameState.joystick_sensitivity
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)

	if Vector2(velocity.x, velocity.z).length() > 0.2:
		_bob_t += delta * 10.0
		mesh_root.position.y = sin(_bob_t) * 0.03
	else:
		mesh_root.position.y = move_toward(mesh_root.position.y, 0.0, delta * 2.0)

	move_and_slide()
