extends CharacterBody3D
class_name PlayerController
## タッチ仮想スティック対応の移動。オリジナルの簡素な人型メッシュ。

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


func _build_visual_if_needed() -> void:
	if mesh_root.get_child_count() > 0:
		_visual = mesh_root
		return
	# オリジナル人型（カプセル+頭）— 既存作品の動物アバターは使わない
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 0.95
	body.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.42, 0.36)
	mat.roughness = 0.85
	body.material_override = mat
	body.position = Vector3(0, 0.55, 0)
	mesh_root.add_child(body)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	head.mesh = sphere
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.91, 0.82, 0.70)
	head.material_override = hmat
	head.position = Vector3(0, 1.15, 0)
	mesh_root.add_child(head)

	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.2
	scarf.mesh = torus
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.75, 0.45, 0.28)
	scarf.material_override = smat
	scarf.position = Vector3(0, 0.95, 0)
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

	# キーボード補助（ブラウザ検証用。iPhoneではスティック優先）
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
		mesh_root.position.y = sin(_bob_t) * 0.04
	else:
		mesh_root.position.y = move_toward(mesh_root.position.y, 0.0, delta * 2.0)

	move_and_slide()
