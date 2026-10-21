extends CharacterBody3D
class_name PlayerController
## 参照: ref-traveler.jpg — ちび・大きな頭・フレア緑ワンピ・麦わら・珊瑚マフラー

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


func _cm(base: Color, shadow: Color = Color.BLACK) -> ShaderMaterial:
	return VisualKit.character_material(base, shadow)


func _mi(mesh: Mesh, mat: Material, pos: Vector3, scale := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.scale = scale
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_root.add_child(n)
	return n


func _build_visual() -> void:
	for c in mesh_root.get_children():
		c.queue_free()

	# Benchクリーム背景でも溶ける白肌禁止
	var cloth := Color(0.26, 0.46, 0.50)
	var cloth_d := Color(0.14, 0.30, 0.34)
	var skin := Color(0.78, 0.58, 0.46)
	var hat := Color(0.74, 0.56, 0.30)
	var scarf_col := Color(0.90, 0.40, 0.28)
	var hair_c := Color(0.20, 0.11, 0.07)
	var boot_c := Color(0.40, 0.28, 0.18)

	# --- 下半身（ブーツを裾から出す） ---
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.12, 8, 10, 0.05, side + 2.0, 0.80), _cm(boot_c, boot_c.darkened(0.3)), Vector3(0.12 * side, 0.10, 0.06), Vector3(1.35, 0.9, 1.6))
		_mi(CraftMeshes.trunk(0.22, 0.075, 0.06, 10), _cm(boot_c.lightened(0.05), boot_c.darkened(0.2)), Vector3(0.11 * side, 0.14, 0.02))

	# 一体フレアワンピ
	_mi(CraftMeshes.trunk(0.68, 0.32, 0.17, 24, 0.0, 0.01), _cm(cloth, cloth_d), Vector3(0, 0.28, 0))

	# 袖
	for side in [-1.0, 1.0]:
		var arm := _mi(CraftMeshes.trunk(0.40, 0.062, 0.048, 10), _cm(cloth, cloth_d), Vector3(0.28 * side, 0.52, 0.04))
		arm.rotation_degrees.z = 22.0 * side
		_mi(CraftMeshes.uv_sphere(0.055, 6, 7), _cm(skin, skin.darkened(0.22)), Vector3(0.38 * side, 0.42, 0.08))

	# --- 頭 ---
	_mi(CraftMeshes.uv_sphere(0.30, 18, 22, 0.01, 3.0, 1.02), _cm(skin, skin.darkened(0.20)), Vector3(0, 1.18, 0))

	# 髪：後ろ＋横のみ（前髪で二重顔にしない）
	_mi(CraftMeshes.uv_sphere(0.27, 12, 16, 0.07, 8.0, 0.95), _cm(hair_c, hair_c.darkened(0.22)), Vector3(0, 1.24, -0.18), Vector3(1.22, 1.05, 0.92))
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.095, 8, 10, 0.05, 5.0 + side, 1.05), _cm(hair_c, hair_c.darkened(0.2)), Vector3(0.24 * side, 1.14, -0.12))

	# 目
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.058, 8, 10), _cm(Color(0.14, 0.08, 0.05), Color(0.04, 0.02, 0.02)), Vector3(0.09 * side, 1.18, 0.26))
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.015, 4, 5)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		shine.material_override = sm
		shine.position = Vector3(0.10 * side, 1.195, 0.295)
		shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(shine)

	# 頬紅
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.022, 6, 7)
		var chm := StandardMaterial3D.new()
		chm.albedo_color = Color(0.92, 0.62, 0.58)
		chm.roughness = 1.0
		chm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		cheek.material_override = chm
		cheek.position = Vector3(0.16 * side, 1.08, 0.24)
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(cheek)

	var mouth := _mi(CraftMeshes.uv_sphere(0.016, 5, 6, 0.0, 1.0, 0.14), _cm(Color(0.50, 0.28, 0.30), Color(0.30, 0.14, 0.16)), Vector3(0, 1.02, 0.275))
	mouth.scale = Vector3(1.1, 0.18, 0.22)

	# 麦わら：つばを厚く・クラウンをはっきり
	_mi(CraftMeshes.uv_sphere(0.40, 12, 28, 0.025, 2.0, 0.22), _cm(hat, hat.darkened(0.30)), Vector3(0, 1.40, -0.02))
	_mi(CraftMeshes.trunk(0.20, 0.18, 0.15, 16), _cm(hat.lightened(0.05), hat.darkened(0.24)), Vector3(0, 1.46, -0.02))
	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.185
	band_m.bottom_radius = 0.185
	band_m.height = 0.05
	band.mesh = band_m
	band.material_override = _cm(Color(0.86, 0.30, 0.22), Color(0.50, 0.12, 0.08))
	band.position = Vector3(0, 1.48, -0.02)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_root.add_child(band)

	# マフラー：首を巻く環＋短い垂れ（棒パイプ禁止）
	_mi(CraftMeshes.uv_sphere(0.16, 12, 16, 0.025, 6.0, 0.72), _cm(scarf_col, scarf_col.darkened(0.24)), Vector3(0, 0.92, 0.0), Vector3(1.45, 0.65, 1.25))
	_mi(CraftMeshes.uv_sphere(0.09, 8, 10, 0.02, 7.0, 0.9), _cm(scarf_col, scarf_col.darkened(0.18)), Vector3(0.12, 0.86, 0.10))
	var tail := _mi(CraftMeshes.trunk(0.22, 0.055, 0.03, 8, 0.02), _cm(scarf_col, scarf_col.darkened(0.2)), Vector3(0.16, 0.72, 0.12))
	tail.rotation_degrees = Vector3(8, 5, 12)

	mesh_root.scale = Vector3(1.10, 1.10, 1.10)


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
