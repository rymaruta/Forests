extends CharacterBody3D
class_name PlayerController
## Forests 独自の旅人。手組みシルエット。

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


func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _build_visual() -> void:
	for c in mesh_root.get_children():
		c.queue_free()

	# 靴
	for side in [-1.0, 1.0]:
		var boot := MeshInstance3D.new()
		boot.mesh = CraftMeshes.uv_sphere(0.09, 5, 7, 0.15, side + 2.0)
		boot.material_override = _mat(Color(0.28, 0.18, 0.12), 0.9)
		boot.position = Vector3(0.09 * side, 0.08, 0.04)
		boot.scale = Vector3(1.1, 0.7, 1.35)
		mesh_root.add_child(boot)

	# 脚
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.mesh = CraftMeshes.trunk(0.32, 0.07, 0.06, 6)
		leg.material_override = _mat(Color(0.2, 0.32, 0.28))
		leg.position = Vector3(0.09 * side, 0.08, 0)
		mesh_root.add_child(leg)

	# 胴
	var torso := MeshInstance3D.new()
	torso.mesh = CraftMeshes.trunk(0.55, 0.2, 0.17, 10)
	torso.material_override = _mat(Color(0.23, 0.46, 0.40))
	torso.position.y = 0.38
	mesh_root.add_child(torso)

	# マント（後ろに広がる）
	var cloak := MeshInstance3D.new()
	cloak.mesh = CraftMeshes.uv_sphere(0.36, 7, 9, 0.12, 5.0)
	cloak.material_override = _mat(Color(0.15, 0.28, 0.24), 0.92)
	cloak.position = Vector3(0, 0.62, -0.1)
	cloak.scale = Vector3(1.15, 1.05, 0.7)
	mesh_root.add_child(cloak)

	# 腕
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = CraftMeshes.trunk(0.34, 0.055, 0.045, 6, 0.02 * side)
		arm.material_override = _mat(Color(0.22, 0.42, 0.36))
		arm.position = Vector3(0.24 * side, 0.72, 0)
		arm.rotation_degrees.z = -18.0 * side
		mesh_root.add_child(arm)

	# 頭
	var head := MeshInstance3D.new()
	head.mesh = CraftMeshes.uv_sphere(0.175, 7, 9, 0.05, 3.0)
	head.material_override = _mat(Color(0.94, 0.84, 0.72), 0.55)
	head.position.y = 1.05
	mesh_root.add_child(head)

	# 髪
	var hair := MeshInstance3D.new()
	hair.mesh = CraftMeshes.uv_sphere(0.19, 6, 8, 0.18, 8.0)
	hair.material_override = _mat(Color(0.25, 0.16, 0.1), 0.88)
	hair.position = Vector3(0, 1.12, -0.02)
	hair.scale = Vector3(1.05, 0.72, 1.05)
	mesh_root.add_child(hair)

	# 目
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.mesh = CraftMeshes.uv_sphere(0.028, 4, 5)
		eye.material_override = _mat(Color(0.12, 0.1, 0.1), 0.4)
		eye.position = Vector3(0.055 * side, 1.06, 0.15)
		mesh_root.add_child(eye)

	# 帽子つば
	var brim := MeshInstance3D.new()
	var brim_m := CylinderMesh.new()
	brim_m.top_radius = 0.3
	brim_m.bottom_radius = 0.3
	brim_m.height = 0.035
	brim.mesh = brim_m
	brim.material_override = _mat(Color(0.58, 0.36, 0.2))
	brim.position.y = 1.18
	mesh_root.add_child(brim)

	# 帽子本体
	var crown := MeshInstance3D.new()
	crown.mesh = CraftMeshes.trunk(0.16, 0.16, 0.08, 8)
	crown.material_override = _mat(Color(0.52, 0.32, 0.17))
	crown.position.y = 1.2
	mesh_root.add_child(crown)

	# マフラー
	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.085
	torus.outer_radius = 0.155
	scarf.mesh = torus
	scarf.material_override = _mat(Color(0.86, 0.48, 0.28), 0.65)
	scarf.position.y = 0.9
	scarf.rotation_degrees.x = 90
	mesh_root.add_child(scarf)

	# マフラーの端
	var tail := MeshInstance3D.new()
	tail.mesh = CraftMeshes.trunk(0.28, 0.05, 0.03, 5, 0.05)
	tail.material_override = _mat(Color(0.86, 0.48, 0.28), 0.65)
	tail.position = Vector3(0.12, 0.72, 0.08)
	tail.rotation_degrees.z = 25
	mesh_root.add_child(tail)


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
