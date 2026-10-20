extends CharacterBody3D
class_name PlayerController
## タッチ仮想スティック対応の移動。オリジナルの旅人シルエット。

const SPEED := 4.2
const ACCEL := 12.0
const GRAVITY := 18.0

var move_input: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var _visual: Node3D
var _bob_t: float = 0.0
var _is_moving: bool = false

@onready var mesh_root: Node3D = $MeshRoot


func _ready() -> void:
	_build_visual_if_needed()
	floor_snap_length = 0.2


func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _build_visual_if_needed() -> void:
	if mesh_root.get_child_count() > 0:
		_visual = mesh_root
		return

	# 体
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.22
	torso_mesh.height = 0.7
	torso.mesh = torso_mesh
	torso.material_override = _mat(Color(0.22, 0.45, 0.38))
	torso.position = Vector3(0, 0.55, 0)
	mesh_root.add_child(torso)

	# 脚（簡易）
	for side in [-1, 1]:
		var leg := MeshInstance3D.new()
		var lm := CapsuleMesh.new()
		lm.radius = 0.07
		lm.height = 0.35
		leg.mesh = lm
		leg.material_override = _mat(Color(0.18, 0.28, 0.26))
		leg.position = Vector3(0.1 * side, 0.18, 0)
		mesh_root.add_child(leg)

	# マント
	var cloak := MeshInstance3D.new()
	var cloak_mesh := SphereMesh.new()
	cloak_mesh.radius = 0.34
	cloak_mesh.height = 0.7
	cloak.mesh = cloak_mesh
	cloak.material_override = _mat(Color(0.16, 0.3, 0.26), 0.9)
	cloak.position = Vector3(0, 0.58, -0.08)
	cloak.scale = Vector3(1.2, 1.05, 0.75)
	mesh_root.add_child(cloak)

	# 頭
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.18
	head.mesh = hs
	head.material_override = _mat(Color(0.94, 0.84, 0.72), 0.55)
	head.position = Vector3(0, 1.05, 0)
	mesh_root.add_child(head)

	# 髪
	var hair := MeshInstance3D.new()
	var hair_m := SphereMesh.new()
	hair_m.radius = 0.19
	hair.mesh = hair_m
	hair.material_override = _mat(Color(0.28, 0.18, 0.12), 0.85)
	hair.position = Vector3(0, 1.12, -0.02)
	hair.scale = Vector3(1.05, 0.7, 1.05)
	mesh_root.add_child(hair)

	# 帽子
	var brim := MeshInstance3D.new()
	var brim_m := CylinderMesh.new()
	brim_m.top_radius = 0.28
	brim_m.bottom_radius = 0.28
	brim_m.height = 0.04
	brim.mesh = brim_m
	brim.material_override = _mat(Color(0.62, 0.38, 0.2))
	brim.position = Vector3(0, 1.18, 0)
	mesh_root.add_child(brim)

	var crown := MeshInstance3D.new()
	var crown_m := CylinderMesh.new()
	crown_m.top_radius = 0.1
	crown_m.bottom_radius = 0.16
	crown_m.height = 0.16
	crown.mesh = crown_m
	crown.material_override = _mat(Color(0.58, 0.34, 0.18))
	crown.position = Vector3(0, 1.28, 0)
	mesh_root.add_child(crown)

	# マフラー
	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.09
	torus.outer_radius = 0.16
	scarf.mesh = torus
	scarf.material_override = _mat(Color(0.86, 0.48, 0.28), 0.65)
	scarf.position = Vector3(0, 0.88, 0)
	scarf.rotation_degrees = Vector3(90, 0, 0)
	mesh_root.add_child(scarf)

	_visual = mesh_root


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

	var sens: float = GameState.joystick_sensitivity
	var target := wish * SPEED * sens
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)

	_is_moving = Vector2(velocity.x, velocity.z).length() > 0.2
	if _is_moving:
		_bob_t += delta * 10.0
		mesh_root.position.y = sin(_bob_t) * 0.035
	else:
		mesh_root.position.y = move_toward(mesh_root.position.y, 0.0, delta * 2.0)

	move_and_slide()
