extends CharacterBody3D
class_name PlayerController
## Forests 旅人。0から手組み。読みやすさと優しさを優先。

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

	# 靴
	for side in [-1.0, 1.0]:
		var boot := MeshInstance3D.new()
		boot.mesh = CraftMeshes.uv_sphere(0.1, 7, 9, 0.1, side + 2.0, 0.68)
		boot.material_override = _cm(ForestsPalette.BOOT, ForestsPalette.BOOT.darkened(0.35))
		boot.position = Vector3(0.105 * side, 0.07, 0.055)
		boot.scale = Vector3(1.2, 0.72, 1.45)
		mesh_root.add_child(boot)

	# 脚（短め）
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.mesh = CraftMeshes.trunk(0.24, 0.078, 0.068, 9)
		leg.material_override = _cm(ForestsPalette.CLOTH_DARK, ForestsPalette.CLOTH_DARK.darkened(0.25))
		leg.position = Vector3(0.1 * side, 0.08, 0)
		mesh_root.add_child(leg)

	# 胴
	var torso := MeshInstance3D.new()
	torso.mesh = CraftMeshes.trunk(0.5, 0.21, 0.18, 14)
	torso.material_override = _cm(ForestsPalette.CLOTH, ForestsPalette.CLOTH_DARK)
	torso.position.y = 0.3
	mesh_root.add_child(torso)

	# 襟
	var collar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.17
	cm.bottom_radius = 0.2
	cm.height = 0.08
	collar.mesh = cm
	collar.material_override = _cm(ForestsPalette.CLOTH.lightened(0.08), ForestsPalette.CLOTH_DARK)
	collar.position.y = 0.78
	mesh_root.add_child(collar)

	# ベルト＋バックル
	var belt := MeshInstance3D.new()
	var belt_m := CylinderMesh.new()
	belt_m.top_radius = 0.2
	belt_m.bottom_radius = 0.2
	belt_m.height = 0.045
	belt.mesh = belt_m
	belt.material_override = _cm(Color(0.42, 0.26, 0.14), Color(0.25, 0.14, 0.08))
	belt.position.y = 0.34
	mesh_root.add_child(belt)
	var buckle := MeshInstance3D.new()
	var bkm := BoxMesh.new()
	bkm.size = Vector3(0.1, 0.08, 0.04)
	buckle.mesh = bkm
	buckle.material_override = _cm(Color(0.85, 0.72, 0.35), Color(0.55, 0.42, 0.18))
	buckle.position = Vector3(0, 0.34, 0.2)
	mesh_root.add_child(buckle)

	# マント
	var cloak := MeshInstance3D.new()
	cloak.mesh = CraftMeshes.cloak_mesh(0.5, 0.62)
	cloak.material_override = _cm(ForestsPalette.CLOTH_DARK, ForestsPalette.CLOTH_DARK.darkened(0.2))
	cloak.position = Vector3(0, 0.8, -0.02)
	mesh_root.add_child(cloak)

	# 腕＋手（体側に下ろす・Tポーズにしない）
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = CraftMeshes.trunk(0.32, 0.055, 0.042, 9, 0.01 * side)
		arm.material_override = _cm(ForestsPalette.CLOTH, ForestsPalette.CLOTH_DARK)
		arm.position = Vector3(0.2 * side, 0.72, 0.02)
		arm.rotation_degrees.z = -12.0 * side
		arm.rotation_degrees.x = 8.0
		mesh_root.add_child(arm)
		var hand := MeshInstance3D.new()
		hand.mesh = CraftMeshes.uv_sphere(0.055, 6, 7)
		hand.material_override = _cm(ForestsPalette.SKIN, ForestsPalette.SKIN.darkened(0.25))
		hand.position = Vector3(0.26 * side, 0.4, 0.06)
		mesh_root.add_child(hand)

	# 頭（大きめ）
	var head := MeshInstance3D.new()
	head.mesh = CraftMeshes.uv_sphere(0.23, 10, 14, 0.035, 3.0, 1.06)
	head.material_override = _cm(ForestsPalette.SKIN, ForestsPalette.SKIN.darkened(0.22))
	head.position.y = 1.02
	mesh_root.add_child(head)

	# 髪
	var hair := MeshInstance3D.new()
	hair.mesh = CraftMeshes.uv_sphere(0.245, 9, 12, 0.18, 8.0, 0.76)
	hair.material_override = _cm(ForestsPalette.HAIR, ForestsPalette.HAIR.darkened(0.25))
	hair.position = Vector3(0, 1.1, -0.035)
	mesh_root.add_child(hair)

	var bang := MeshInstance3D.new()
	bang.mesh = CraftMeshes.uv_sphere(0.125, 7, 9, 0.22, 4.0, 0.52)
	bang.material_override = _cm(ForestsPalette.HAIR, ForestsPalette.HAIR.darkened(0.2))
	bang.position = Vector3(0, 1.1, 0.15)
	bang.scale = Vector3(1.45, 0.68, 0.55)
	mesh_root.add_child(bang)

	# 目
	for side in [-1.0, 1.0]:
		var white := MeshInstance3D.new()
		white.mesh = CraftMeshes.uv_sphere(0.048, 6, 7, 0.0, 1.0, 0.82)
		white.material_override = _cm(Color(0.98, 0.98, 0.96), Color(0.85, 0.85, 0.88))
		white.position = Vector3(0.075 * side, 1.02, 0.19)
		mesh_root.add_child(white)
		var iris := MeshInstance3D.new()
		iris.mesh = CraftMeshes.uv_sphere(0.03, 5, 6)
		iris.material_override = _cm(Color(0.22, 0.36, 0.3), Color(0.1, 0.18, 0.14))
		iris.position = Vector3(0.075 * side, 1.015, 0.22)
		mesh_root.add_child(iris)
		var shine := MeshInstance3D.new()
		shine.mesh = CraftMeshes.uv_sphere(0.011, 4, 5)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1, 1, 1)
		sm.emission_enabled = true
		sm.emission = Color(1, 1, 1)
		sm.emission_energy_multiplier = 0.5
		shine.material_override = sm
		shine.position = Vector3(0.085 * side, 1.03, 0.235)
		mesh_root.add_child(shine)

	# 眉
	for side in [-1.0, 1.0]:
		var brow := MeshInstance3D.new()
		brow.mesh = CraftMeshes.uv_sphere(0.022, 4, 5, 0.0, 1.0, 0.35)
		brow.material_override = _cm(ForestsPalette.HAIR, ForestsPalette.HAIR.darkened(0.2))
		brow.position = Vector3(0.075 * side, 1.08, 0.2)
		brow.scale = Vector3(1.6, 0.5, 0.6)
		brow.rotation_degrees.z = -8.0 * side
		mesh_root.add_child(brow)

	# ほっぺ
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.mesh = CraftMeshes.uv_sphere(0.032, 5, 6, 0.0, 1.0, 0.65)
		var chm := StandardMaterial3D.new()
		chm.albedo_color = Color(0.98, 0.7, 0.68)
		chm.emission_enabled = true
		chm.emission = Color(0.95, 0.55, 0.5)
		chm.emission_energy_multiplier = 0.18
		chm.roughness = 0.6
		cheek.material_override = chm
		cheek.position = Vector3(0.15 * side, 0.95, 0.155)
		mesh_root.add_child(cheek)

	# 口
	var mouth := MeshInstance3D.new()
	mouth.mesh = CraftMeshes.uv_sphere(0.02, 4, 5, 0.0, 1.0, 0.35)
	mouth.material_override = _cm(Color(0.78, 0.42, 0.44), Color(0.55, 0.25, 0.28))
	mouth.position = Vector3(0, 0.91, 0.21)
	mouth.scale = Vector3(1.5, 0.4, 0.55)
	mesh_root.add_child(mouth)

	# 帽子（少し柔らかく傾ける）
	var brim := MeshInstance3D.new()
	var brim_m := CylinderMesh.new()
	brim_m.top_radius = 0.38
	brim_m.bottom_radius = 0.38
	brim_m.height = 0.028
	brim_m.radial_segments = 28
	brim.mesh = brim_m
	brim.material_override = _cm(ForestsPalette.HAT, ForestsPalette.HAT.darkened(0.3))
	brim.position = Vector3(0.02, 1.17, 0)
	brim.rotation_degrees.z = -6
	mesh_root.add_child(brim)

	var crown := MeshInstance3D.new()
	crown.mesh = CraftMeshes.trunk(0.22, 0.185, 0.095, 14)
	crown.material_override = _cm(ForestsPalette.HAT.lightened(0.05), ForestsPalette.HAT.darkened(0.28))
	crown.position = Vector3(0.02, 1.19, 0)
	crown.rotation_degrees.z = -6
	mesh_root.add_child(crown)

	var band := MeshInstance3D.new()
	var band_m := CylinderMesh.new()
	band_m.top_radius = 0.195
	band_m.bottom_radius = 0.195
	band_m.height = 0.038
	band.mesh = band_m
	band.material_override = _cm(Color(0.55, 0.28, 0.18), Color(0.35, 0.16, 0.1))
	band.position.y = 1.22
	mesh_root.add_child(band)

	# マフラー
	var scarf := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.095
	torus.outer_radius = 0.175
	torus.rings = 18
	torus.ring_segments = 12
	scarf.mesh = torus
	scarf.material_override = _cm(ForestsPalette.SCARF, ForestsPalette.SCARF.darkened(0.3))
	scarf.position.y = 0.84
	scarf.rotation_degrees.x = 90
	mesh_root.add_child(scarf)

	var tail := MeshInstance3D.new()
	tail.mesh = CraftMeshes.trunk(0.34, 0.058, 0.028, 7, 0.07)
	tail.material_override = _cm(ForestsPalette.SCARF, ForestsPalette.SCARF.darkened(0.28))
	tail.position = Vector3(0.15, 0.62, 0.1)
	tail.rotation_degrees.z = 30
	mesh_root.add_child(tail)

	mesh_root.scale = Vector3(1.08, 1.08, 1.08)


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
