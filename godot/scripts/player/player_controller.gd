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

	# Benchクリーム背景でも溶ける白肌禁止：参照寄りの暖オークル
	var cloth := Color(0.28, 0.48, 0.50)
	var cloth_d := Color(0.16, 0.32, 0.34)
	var skin := Color(0.88, 0.72, 0.58)
	var hat := Color(0.78, 0.60, 0.34)
	var scarf_col := Color(0.88, 0.42, 0.30)
	var hair_c := Color(0.22, 0.12, 0.08)
	var boot_c := Color(0.36, 0.24, 0.16)

	# --- 下半身 ---
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.11, 8, 10, 0.05, side + 2.0, 0.75), _cm(boot_c, boot_c.darkened(0.3)), Vector3(0.11 * side, 0.09, 0.05), Vector3(1.3, 0.85, 1.55))
		_mi(CraftMeshes.trunk(0.20, 0.07, 0.058, 10), _cm(boot_c.lightened(0.05), boot_c.darkened(0.2)), Vector3(0.10 * side, 0.12, 0))

	# 一体フレアワンピ（裾を広げて参照の鐘形）
	_mi(CraftMeshes.trunk(0.72, 0.30, 0.16, 24, 0.0, 0.01), _cm(cloth, cloth_d), Vector3(0, 0.22, 0))

	# 袖：外側にはっきり出す
	for side in [-1.0, 1.0]:
		var arm := _mi(CraftMeshes.trunk(0.44, 0.06, 0.045, 10), _cm(cloth, cloth_d), Vector3(0.30 * side, 0.40, 0.05))
		arm.rotation_degrees.z = 20.0 * side
		_mi(CraftMeshes.uv_sphere(0.055, 6, 7), _cm(skin, skin.darkened(0.22)), Vector3(0.36 * side, 0.38, 0.1))

	# --- 頭 ---
	_mi(CraftMeshes.uv_sphere(0.32, 18, 22, 0.012, 3.0, 1.05), _cm(skin, skin.darkened(0.18)), Vector3(0, 1.14, 0))

	# 髪：後ろ＋横＋前髪で参照の短髪ボリューム
	_mi(CraftMeshes.uv_sphere(0.28, 12, 16, 0.08, 8.0, 0.95), _cm(hair_c, hair_c.darkened(0.22)), Vector3(0, 1.22, -0.20), Vector3(1.25, 1.08, 0.95))
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.10, 8, 10, 0.06, 5.0 + side, 1.1), _cm(hair_c, hair_c.darkened(0.2)), Vector3(0.26 * side, 1.10, -0.16))
		_mi(CraftMeshes.uv_sphere(0.07, 7, 9, 0.05, 6.0 + side, 1.0), _cm(hair_c, hair_c.darkened(0.18)), Vector3(0.20 * side, 1.24, 0.06))
	var bang := _mi(CraftMeshes.uv_sphere(0.07, 8, 10, 0.05, 4.0, 0.45), _cm(hair_c, hair_c.darkened(0.18)), Vector3(0, 1.32, 0.14))
	bang.scale = Vector3(1.55, 0.28, 0.55)

	# 目：大きめ・正面にしっかり
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.055, 8, 10), _cm(Color(0.16, 0.09, 0.06), Color(0.04, 0.02, 0.02)), Vector3(0.085 * side, 1.12, 0.255))
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.014, 4, 5)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		shine.material_override = sm
		shine.position = Vector3(0.095 * side, 1.135, 0.29)
		shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(shine)

	# 頬紅
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.02, 6, 7)
		var chm := StandardMaterial3D.new()
		chm.albedo_color = Color(0.98, 0.74, 0.72)
		chm.roughness = 1.0
		chm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		cheek.material_override = chm
		cheek.position = Vector3(0.15 * side, 1.04, 0.24)
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(cheek)

	var mouth := _mi(CraftMeshes.uv_sphere(0.014, 5, 6, 0.0, 1.0, 0.12), _cm(Color(0.48, 0.28, 0.3), Color(0.3, 0.15, 0.16)), Vector3(0, 0.99, 0.275))
	mouth.scale = Vector3(1.05, 0.16, 0.22)

	# 麦わら帽子：厚いつば＋クラウン（薄い円盤禁止）
	_mi(CraftMeshes.uv_sphere(0.42, 10, 28, 0.03, 2.0, 0.16), _cm(hat, hat.darkened(0.28)), Vector3(0, 1.36, -0.02))
	_mi(CraftMeshes.trunk(0.18, 0.17, 0.14, 16), _cm(hat.lightened(0.04), hat.darkened(0.22)), Vector3(0, 1.40, -0.02))
	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.175
	band_m.bottom_radius = 0.175
	band_m.height = 0.045
	band.mesh = band_m
	band.material_override = _cm(Color(0.82, 0.28, 0.22), Color(0.48, 0.10, 0.08))
	band.position = Vector3(0, 1.42, -0.02)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_root.add_child(band)

	# マフラー：頭と胴をつなぐ（浮き頭を防ぐ）・ボリュームを残す
	_mi(CraftMeshes.uv_sphere(0.17, 12, 16, 0.03, 6.0, 0.80), _cm(scarf_col, scarf_col.darkened(0.24)), Vector3(0, 0.90, 0.02), Vector3(1.55, 0.78, 1.35))
	_mi(CraftMeshes.uv_sphere(0.11, 8, 10, 0.03, 7.0, 0.90), _cm(scarf_col, scarf_col.darkened(0.18)), Vector3(0.10, 0.88, 0.12))
	var tail := _mi(CraftMeshes.trunk(0.34, 0.06, 0.03, 8, 0.04), _cm(scarf_col, scarf_col.darkened(0.2)), Vector3(0.14, 0.66, 0.16))
	tail.rotation_degrees = Vector3(18, 10, 24)

	mesh_root.scale = Vector3(1.12, 1.12, 1.12)


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
