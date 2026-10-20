extends Node3D
## AssetBench — 参照と同じ比較条件で1アセットだけ撮る台。
## 灰背景・柔らかい3灯・HUDなし。ワールド写真は最終確認だけ。

@export_enum("tree", "cottage", "traveler") var subject: String = "tree"


func _ready() -> void:
	_build_stage()
	_spawn_subject()
	if subject == "tree":
		call_deferred("_bake_csg_canopies")


func _bake_csg_canopies() -> void:
	## CSGユニオンをArrayMeshへ焼き、フェルトシェーダを載せる
	await get_tree().create_timer(0.35).timeout
	_bake_csg_in($Subject)


func _bake_csg_in(n: Node) -> void:
	for c in n.get_children():
		if c is CSGCombiner3D:
			var comb := c as CSGCombiner3D
			var felt: Material = comb.get_meta("felt_material", null)
			var data: Array = comb.get_meshes()
			if data.size() >= 2 and data[1] is Mesh:
				var raw: Mesh = data[1] as Mesh
				var mi := MeshInstance3D.new()
				mi.mesh = CraftMeshes.weld_smooth(raw)
				mi.transform = comb.transform
				if felt:
					mi.material_override = felt
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var parent := comb.get_parent()
				parent.add_child(mi)
				comb.queue_free()
		else:
			_bake_csg_in(c)


func _build_stage() -> void:
	# 参照シート相当のニュートラル灰
	RenderingServer.set_default_clear_color(Color(0.78, 0.78, 0.76))

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.78, 0.78, 0.76)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.86, 0.84)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.92
	env.adjustment_contrast = 1.02
	$WorldEnvironment.environment = env

	# 参照シート相当：柔らかい拡散光（硬い自己影を出さない）
	var key: DirectionalLight3D = $KeyLight
	key.light_color = Color(1.0, 0.98, 0.94)
	# 参照相当：柔らかいが立体感が残るキー
	key.light_energy = 0.85
	key.light_specular = 0.0
	key.shadow_enabled = true
	key.shadow_blur = 4.5
	key.shadow_opacity = 0.14
	key.rotation_degrees = Vector3(-48, -30, 0)

	var fill: DirectionalLight3D = $FillLight
	fill.light_color = Color(0.9, 0.92, 0.95)
	fill.light_energy = 0.45
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-28, 55, 0)

	var rim: DirectionalLight3D = $RimLight
	rim.light_color = Color(0.95, 0.95, 0.98)
	rim.light_energy = 0.22
	rim.light_specular = 0.0
	rim.shadow_enabled = false
	rim.rotation_degrees = Vector3(-12, 155, 0)

	# 参照シート同様、床＝背景灰（unshadedで白飛び防止）
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	floor_mi.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(0.78, 0.78, 0.76)
	fm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	floor_mi.material_override = fm
	floor_mi.position.y = 0.0
	floor_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mi)


func _spawn_subject() -> void:
	var hold: Node3D = $Subject
	for c in hold.get_children():
		c.queue_free()

	var cam: Camera3D = $Camera3D
	match subject:
		"tree":
			var rng := RandomNumberGenerator.new()
			rng.seed = 2901  # ヒーロー固定シード
			var tree := NatureFactory.deciduous_tree_hero(rng)
			hold.add_child(tree)
			# 参照シート相当：根〜冠が切れない余白つき正面
			cam.position = Vector3(0.15, 2.35, 8.4)
			cam.look_at(Vector3(0.0, 1.55, 0.0), Vector3.UP)
			cam.fov = 28.0
		"cottage":
			var home := NatureFactory.cottage()
			hold.add_child(home)
			# 正面
			home.rotation.y = 0.0
			cam.position = Vector3(0.0, 2.4, 8.5)
			cam.look_at(Vector3(0.0, 1.6, 0.0), Vector3.UP)
			cam.fov = 35.0
		"traveler":
			var packed: PackedScene = load("res://scenes/player/Player.tscn")
			var p: Node3D = packed.instantiate()
			hold.add_child(p)
			p.position = Vector3(0, 0, 0)
			if p.has_method("set_facing_yaw"):
				p.set_facing_yaw(0.0)
			# 物理オフで立ち姿固定
			if p is CharacterBody3D:
				(p as CharacterBody3D).set_physics_process(false)
				(p as CharacterBody3D).velocity = Vector3.ZERO
			cam.position = Vector3(0.0, 1.15, 3.4)
			cam.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
			cam.fov = 28.0
		_:
			push_warning("AssetBench: unknown subject '%s'" % subject)

	cam.current = true
