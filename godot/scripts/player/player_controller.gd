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


func _cm(base: Color, shadow: Color = Color.BLACK, flock: float = -1.0) -> ShaderMaterial:
	var m: ShaderMaterial = VisualKit.character_material(base, shadow)
	if flock >= 0.0:
		m.set_shader_parameter("flock_amt", flock)
	return m


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

	# 袖＋手元：trunkはローカル+Yなので X≈180 で下ろす
	for side in [-1.0, 1.0]:
		var arm_root := Node3D.new()
		arm_root.position = Vector3(0.22 * side, 0.80, 0.02)
		arm_root.rotation_degrees.x = 168.0
		arm_root.rotation_degrees.z = 12.0 * side
		mesh_root.add_child(arm_root)
		var upper := MeshInstance3D.new()
		upper.mesh = CraftMeshes.trunk(0.34, 0.07, 0.052, 12)
		upper.material_override = _cm(cloth, cloth_d)
		upper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm_root.add_child(upper)
		var hand := MeshInstance3D.new()
		hand.mesh = CraftMeshes.uv_sphere(0.058, 7, 8)
		hand.material_override = _cm(skin, skin.darkened(0.22))
		hand.position = Vector3(0.0, 0.36, 0.0)
		hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm_root.add_child(hand)

	# --- 頭 ---
	_mi(CraftMeshes.uv_sphere(0.30, 18, 22, 0.01, 3.0, 1.02), _cm(skin, skin.darkened(0.20)), Vector3(0, 1.18, 0))

	# 髪：後ろ＋横＋つば下に少し見せる（二重顔は出さない）
	_mi(CraftMeshes.uv_sphere(0.28, 12, 16, 0.08, 8.0, 0.95), _cm(hair_c, hair_c.darkened(0.22)), Vector3(0, 1.26, -0.14), Vector3(1.28, 1.08, 0.98))
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.11, 8, 10, 0.06, 5.0 + side, 1.05), _cm(hair_c, hair_c.darkened(0.2)), Vector3(0.26 * side, 1.16, -0.04))
		_mi(CraftMeshes.uv_sphere(0.07, 7, 8, 0.04, 6.2 + side, 1.1), _cm(hair_c, hair_c.darkened(0.18)), Vector3(0.20 * side, 1.08, 0.10))

	# 目：丸い黒＋白いハイライト
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.062, 9, 11), _cm(Color(0.12, 0.07, 0.05), Color(0.03, 0.02, 0.02)), Vector3(0.095 * side, 1.19, 0.265))
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.018, 5, 6)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		shine.material_override = sm
		shine.position = Vector3(0.105 * side, 1.205, 0.305)
		shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(shine)

	# 頬紅：極小・薄色（第二の目に見えない）
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.011, 5, 6)
		var chm := StandardMaterial3D.new()
		chm.albedo_color = Color(0.86, 0.64, 0.58)
		chm.roughness = 1.0
		chm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		cheek.material_override = chm
		cheek.position = Vector3(0.175 * side, 1.055, 0.258)
		cheek.scale = Vector3(1.5, 0.55, 0.5)
		cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(cheek)

	var mouth := _mi(CraftMeshes.uv_sphere(0.016, 5, 6, 0.0, 1.0, 0.14), _cm(Color(0.50, 0.28, 0.30), Color(0.30, 0.14, 0.16)), Vector3(0, 1.02, 0.275))
	mouth.scale = Vector3(1.1, 0.18, 0.22)

	# 麦わら：柔らかいつば＋背の高い麦色クラウン（織り flock 強め）
	_mi(CraftMeshes.uv_sphere(0.52, 14, 30, 0.04, 2.0, 0.28), _cm(hat, hat.darkened(0.34), 0.88), Vector3(0, 1.36, -0.02), Vector3(1.05, 0.85, 1.05))
	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.22
	band_m.bottom_radius = 0.22
	band_m.height = 0.03
	band.mesh = band_m
	band.material_override = _cm(Color(0.88, 0.32, 0.22), Color(0.52, 0.12, 0.08), 0.40)
	band.position = Vector3(0, 1.40, -0.02)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_root.add_child(band)
	_mi(CraftMeshes.trunk(0.34, 0.21, 0.16, 18), _cm(Color(0.90, 0.72, 0.42), Color(0.58, 0.40, 0.20), 0.86), Vector3(0, 1.46, -0.02))
	_mi(CraftMeshes.uv_sphere(0.20, 12, 14, 0.025, 2.8, 0.80), _cm(Color(0.92, 0.74, 0.44), Color(0.60, 0.42, 0.22), 0.84), Vector3(0, 1.72, -0.02))

	# マフラー：首に太い巻き＋片側の短い端（リボン垂れ禁止）
	_mi(CraftMeshes.uv_sphere(0.18, 14, 18, 0.03, 6.0, 0.55), _cm(scarf_col, scarf_col.darkened(0.26), 0.55), Vector3(0, 0.88, 0.06), Vector3(1.55, 0.70, 1.35))
	_mi(CraftMeshes.uv_sphere(0.12, 10, 12, 0.025, 7.0, 0.85), _cm(scarf_col, scarf_col.darkened(0.20), 0.50), Vector3(0.16, 0.82, 0.18))
	_mi(CraftMeshes.uv_sphere(0.09, 8, 10, 0.02, 7.5, 0.9), _cm(scarf_col, scarf_col.darkened(0.18), 0.48), Vector3(0.20, 0.70, 0.16))

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
