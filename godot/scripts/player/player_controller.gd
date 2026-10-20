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


func _build_visual() -> void:
	for c in mesh_root.get_children():
		c.queue_free()

	# 参照色（くすみティール・珊瑚・麦わら）
	var cloth := Color(0.28, 0.48, 0.46)
	var cloth_d := Color(0.18, 0.34, 0.33)
	var skin := ForestsPalette.SKIN
	var hat := Color(0.78, 0.62, 0.38)
	var scarf_col := Color(0.82, 0.42, 0.32)
	var hair_c := Color(0.26, 0.16, 0.1)
	var boot_c := Color(0.36, 0.24, 0.16)

	# ブーツ（チャンキー）
	for side in [-1.0, 1.0]:
		var boot := MeshInstance3D.new()
		boot.mesh = CraftMeshes.uv_sphere(0.095, 7, 9, 0.08, side + 2.0, 0.65)
		boot.material_override = _cm(boot_c, boot_c.darkened(0.3))
		boot.position = Vector3(0.09 * side, 0.07, 0.05)
		boot.scale = Vector3(1.3, 0.75, 1.55)
		mesh_root.add_child(boot)

	# レギンス
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.mesh = CraftMeshes.trunk(0.2, 0.07, 0.06, 9)
		leg.material_override = _cm(boot_c.lightened(0.08), boot_c.darkened(0.2))
		leg.position = Vector3(0.085 * side, 0.08, 0)
		mesh_root.add_child(leg)

	# Aラインのワンピ（参照どおりフレア）
	var skirt := MeshInstance3D.new()
	skirt.mesh = CraftMeshes.trunk(0.48, 0.28, 0.16, 16, 0.0, 0.015)
	skirt.material_override = _cm(cloth, cloth_d)
	skirt.position.y = 0.24
	mesh_root.add_child(skirt)

	var torso := MeshInstance3D.new()
	torso.mesh = CraftMeshes.trunk(0.32, 0.16, 0.15, 14)
	torso.material_override = _cm(cloth.lightened(0.03), cloth_d)
	torso.position.y = 0.62
	mesh_root.add_child(torso)

	# 長袖（参照どおり体に沿って下ろす）
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = CraftMeshes.trunk(0.34, 0.055, 0.042, 9, 0.01 * side)
		arm.material_override = _cm(cloth, cloth_d)
		arm.position = Vector3(0.2 * side, 0.78, 0.02)
		arm.rotation_degrees.z = -10.0 * side
		arm.rotation_degrees.x = 10.0
		mesh_root.add_child(arm)
		var hand := MeshInstance3D.new()
		hand.mesh = CraftMeshes.uv_sphere(0.048, 6, 7)
		hand.material_override = _cm(skin, skin.darkened(0.22))
		hand.position = Vector3(0.24 * side, 0.46, 0.08)
		mesh_root.add_child(hand)

	# 頭（参照：大きいちび頭）
	var head := MeshInstance3D.new()
	head.mesh = CraftMeshes.uv_sphere(0.3, 14, 18, 0.02, 3.0, 1.02)
	head.material_override = _cm(skin, skin.darkened(0.16))
	head.position.y = 1.12
	mesh_root.add_child(head)

	# ボリュームのあるボブ（塊）
	var hair := MeshInstance3D.new()
	hair.mesh = CraftMeshes.uv_sphere(0.32, 12, 16, 0.12, 8.0, 0.82)
	hair.material_override = _cm(hair_c, hair_c.darkened(0.22))
	hair.position = Vector3(0, 1.2, -0.04)
	mesh_root.add_child(hair)
	var bang := MeshInstance3D.new()
	bang.mesh = CraftMeshes.uv_sphere(0.15, 8, 10, 0.12, 4.0, 0.55)
	bang.material_override = _cm(hair_c, hair_c.darkened(0.18))
	bang.position = Vector3(0, 1.18, 0.18)
	bang.scale = Vector3(1.6, 0.65, 0.5)
	mesh_root.add_child(bang)

	# 大きな茶色の目（埋め込み）
	for side in [-1.0, 1.0]:
		var iris := MeshInstance3D.new()
		iris.mesh = CraftMeshes.uv_sphere(0.042, 7, 9, 0.0, 1.0, 0.92)
		iris.material_override = _cm(Color(0.22, 0.14, 0.1), Color(0.08, 0.05, 0.04))
		iris.position = Vector3(0.09 * side, 1.12, 0.255)
		mesh_root.add_child(iris)
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.012, 4, 5)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.emission_enabled = true
		sm.emission = Color(1, 1, 1)
		sm.emission_energy_multiplier = 0.5
		shine.material_override = sm
		shine.position = Vector3(0.1 * side, 1.135, 0.285)
		mesh_root.add_child(shine)

	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.04, 6, 7, 0.0, 1.0, 0.7)
		var chm := StandardMaterial3D.new()
		chm.albedo_color = Color(0.95, 0.62, 0.6)
		chm.emission_enabled = true
		chm.emission = Color(0.9, 0.45, 0.42)
		chm.emission_energy_multiplier = 0.18
		chm.roughness = 0.7
		cheek.material_override = chm
		cheek.position = Vector3(0.2 * side, 1.02, 0.2)
		mesh_root.add_child(cheek)

	# 口は細い線（穴に見えないよう薄く暗い帯）
	var mouth := MeshInstance3D.new()
	mouth.mesh = CraftMeshes.uv_sphere(0.028, 5, 6, 0.0, 1.0, 0.22)
	mouth.material_override = _cm(Color(0.55, 0.32, 0.34), Color(0.35, 0.18, 0.2))
	mouth.position = Vector3(0, 0.98, 0.275)
	mouth.scale = Vector3(1.1, 0.28, 0.35)
	mesh_root.add_child(mouth)

	# 麦わら帽子（顔を隠さない位置・サイズ）
	var brim := MeshInstance3D.new()
	brim.mesh = CraftMeshes.uv_sphere(0.36, 6, 24, 0.04, 2.0, 0.1)
	brim.material_override = _cm(hat, hat.darkened(0.25))
	brim.position = Vector3(0.01, 1.34, 0)
	brim.rotation_degrees.z = -3
	mesh_root.add_child(brim)

	var crown := MeshInstance3D.new()
	crown.mesh = CraftMeshes.trunk(0.2, 0.19, 0.1, 14)
	crown.material_override = _cm(hat.lightened(0.04), hat.darkened(0.22))
	crown.position = Vector3(0.01, 1.36, 0)
	crown.rotation_degrees.z = -3
	mesh_root.add_child(crown)

	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.195
	band_m.bottom_radius = 0.195
	band_m.height = 0.04
	band.mesh = band_m
	band.material_override = _cm(Color(0.72, 0.22, 0.2), Color(0.45, 0.12, 0.1))
	band.position = Vector3(0.01, 1.4, 0)
	mesh_root.add_child(band)

	# 厚めの珊瑚マフラー
	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.11
	torus.outer_radius = 0.2
	torus.rings = 18
	torus.ring_segments = 12
	scarf.mesh = torus
	scarf.material_override = _cm(scarf_col, scarf_col.darkened(0.25))
	scarf.position.y = 0.9
	scarf.rotation_degrees.x = 90
	mesh_root.add_child(scarf)

	var tail := MeshInstance3D.new()
	tail.mesh = CraftMeshes.trunk(0.36, 0.06, 0.028, 7, 0.08)
	tail.material_override = _cm(scarf_col, scarf_col.darkened(0.22))
	tail.position = Vector3(0.16, 0.66, 0.1)
	tail.rotation_degrees.z = 32
	mesh_root.add_child(tail)

	mesh_root.scale = Vector3(1.15, 1.15, 1.15)


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
