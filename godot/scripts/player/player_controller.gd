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
	var cloth := Color(0.18, 0.40, 0.44)
	var cloth_d := Color(0.09, 0.24, 0.28)
	var skin := Color(0.78, 0.56, 0.42)
	var hat := Color(0.78, 0.60, 0.32)
	var scarf_col := Color(0.92, 0.42, 0.30)
	var hair_c := Color(0.16, 0.09, 0.05)
	var boot_c := Color(0.32, 0.20, 0.12)

	# --- 下半身（暗いレギンス＋チャンキーブーツ） ---
	var leg_c := Color(0.16, 0.10, 0.07)
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.trunk(0.26, 0.048, 0.042, 10), _cm(leg_c, leg_c.darkened(0.30)), Vector3(0.10 * side, 0.22, 0.02))
		# 靴：丸いチャンキー体積（正面でも厚みが読める）
		_mi(CraftMeshes.uv_sphere(0.16, 12, 14, 0.02, side + 2.0, 0.30), _cm(boot_c, boot_c.darkened(0.28), 0.55), Vector3(0.11 * side, 0.10, 0.12), Vector3(1.45, 1.25, 1.85))
		_mi(CraftMeshes.uv_sphere(0.12, 10, 12, 0.015, side + 3.0, 0.35), _cm(boot_c.lightened(0.04), boot_c.darkened(0.20), 0.50), Vector3(0.11 * side, 0.20, 0.04), Vector3(1.20, 1.15, 1.15))

	# 一体フレアワンピ（裾を広げて脚を見せる）
	_mi(CraftMeshes.trunk(0.64, 0.36, 0.155, 24, 0.0, 0.01), _cm(cloth, cloth_d, 0.58), Vector3(0, 0.30, 0))

	# 袖＋手元：体より前・外側。手先は太い丸い拳で袖先を覆う
	for side in [-1.0, 1.0]:
		var arm_root := Node3D.new()
		arm_root.position = Vector3(0.32 * side, 0.78, 0.14)
		arm_root.rotation_degrees.x = 162.0
		arm_root.rotation_degrees.z = 12.0 * side
		mesh_root.add_child(arm_root)
		var upper := MeshInstance3D.new()
		upper.mesh = CraftMeshes.trunk(0.38, 0.082, 0.064, 14)
		upper.material_override = _cm(cloth, cloth_d, 0.58)
		upper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm_root.add_child(upper)
		var hand := MeshInstance3D.new()
		hand.mesh = CraftMeshes.uv_sphere(0.068, 10, 12)
		hand.material_override = _cm(skin, skin.darkened(0.16))
		hand.position = Vector3(0.0, 0.38, 0.0)
		hand.scale = Vector3(1.28, 1.10, 1.22)
		hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm_root.add_child(hand)

	# --- 頭 ---
	_mi(CraftMeshes.uv_sphere(0.30, 18, 22, 0.01, 3.0, 1.02), _cm(skin, skin.darkened(0.18)), Vector3(0, 1.18, 0))

	# 髪：後ろボリューム＋耳後ろのみ（目下に影線が出ないよう前へ出さない）
	_mi(CraftMeshes.uv_sphere(0.30, 12, 16, 0.08, 8.0, 0.95), _cm(hair_c, hair_c.darkened(0.22)), Vector3(0, 1.34, -0.26), Vector3(1.32, 1.12, 1.05))
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.095, 8, 10, 0.05, 5.0 + side, 1.05), _cm(hair_c, hair_c.darkened(0.2)), Vector3(0.26 * side, 1.22, -0.28), Vector3(1.0, 1.10, 0.90))

	# 目：横に広い丸。頭表面に軽く載せる（沈み込み影線禁止）
	for side in [-1.0, 1.0]:
		_mi(CraftMeshes.uv_sphere(0.048, 10, 12), _cm(Color(0.10, 0.06, 0.04), Color(0.02, 0.01, 0.01), 0.08), Vector3(0.095 * side, 1.22, 0.288), Vector3(1.20, 0.95, 0.70))
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.016, 5, 6)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		shine.material_override = sm
		shine.position = Vector3(0.105 * side, 1.232, 0.325)
		shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_root.add_child(shine)

	# 頬紅は省略（薄い球が傷跡ラインに読まれるため）
	# 小さな鼻（参照の控えめ鼻）
	_mi(CraftMeshes.uv_sphere(0.022, 6, 7), _cm(skin.darkened(0.04), skin.darkened(0.16), 0.20), Vector3(0, 1.14, 0.295), Vector3(0.90, 0.75, 1.05))

	var mouth := _mi(CraftMeshes.uv_sphere(0.014, 5, 6, 0.0, 1.0, 0.12), _cm(Color(0.55, 0.32, 0.34), Color(0.32, 0.16, 0.18), 0.15), Vector3(0, 1.05, 0.285))
	mouth.scale = Vector3(1.10, 0.18, 0.22)

	# 麦わら：広いつば＋丸い麦色クラウン＋太い赤帯
	var straw := Color(0.88, 0.70, 0.38)
	var straw_d := Color(0.55, 0.38, 0.18)
	_mi(CraftMeshes.uv_sphere(0.54, 14, 30, 0.03, 2.0, 0.28), _cm(hat, hat.darkened(0.30), 0.90), Vector3(0, 1.28, -0.02), Vector3(1.20, 0.78, 1.20))
	_mi(CraftMeshes.uv_sphere(0.24, 14, 16, 0.02, 2.6, 0.42), _cm(straw, straw_d, 0.85), Vector3(0, 1.48, -0.02), Vector3(1.15, 1.05, 1.15))
	_mi(CraftMeshes.uv_sphere(0.18, 12, 14, 0.015, 2.9, 0.50), _cm(straw.lightened(0.04), straw_d, 0.82), Vector3(0, 1.58, -0.02), Vector3(1.05, 0.85, 1.05))
	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.255
	band_m.bottom_radius = 0.262
	band_m.height = 0.058
	band.mesh = band_m
	# 帯は flock 弱め＝赤が麦色に濁らない（参照の太い布帯）
	band.material_override = _cm(Color(0.90, 0.32, 0.16), Color(0.52, 0.12, 0.05), 0.08)
	band.position = Vector3(0, 1.34, -0.02)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_root.add_child(band)

	# マフラー：太い巻き＋片側の短い端（腕に刺さらず後ろ寄り）
	_mi(CraftMeshes.uv_sphere(0.23, 14, 18, 0.02, 6.0, 0.50), _cm(scarf_col, scarf_col.darkened(0.28), 0.70), Vector3(0, 0.88, 0.08), Vector3(1.72, 0.85, 1.40))
	_mi(CraftMeshes.uv_sphere(0.13, 10, 12, 0.015, 7.0, 0.88), _cm(scarf_col, scarf_col.darkened(0.22), 0.62), Vector3(0.16, 0.78, -0.06))
	_mi(CraftMeshes.uv_sphere(0.095, 8, 10, 0.012, 7.5, 0.92), _cm(scarf_col, scarf_col.darkened(0.18), 0.58), Vector3(0.20, 0.62, -0.10))

	mesh_root.scale = Vector3(1.06, 1.14, 1.06)


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
