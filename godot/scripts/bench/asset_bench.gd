extends Node3D
## AssetBench — 参照と同じ比較条件で1アセットだけ撮る台。
## 灰背景・柔らかい3灯・HUDなし。ワールド写真は最終確認だけ。

@export_enum("tree", "tree_canopy", "tree_trunk", "tree_toes", "cottage", "traveler") var subject: String = "tree"


func _ready() -> void:
	_build_stage()
	_spawn_subject()
	if subject == "tree":
		call_deferred("_bake_csg_canopies")


func _bake_csg_canopies() -> void:
	## CSGユニオンをArrayMeshへ焼き（冠／幹＋趾）
	await get_tree().create_timer(0.55).timeout
	# CSG メッシュ確定のため数フレーム待つ
	for _i in 8:
		await get_tree().process_frame
	_bake_csg_in($Subject)


func _bake_csg_in(n: Node) -> void:
	for c in n.get_children():
		if c is CSGCombiner3D:
			var comb := c as CSGCombiner3D
			var mat: Material = null
			if comb.has_meta("felt_material"):
				mat = comb.get_meta("felt_material") as Material
			elif comb.has_meta("bake_material"):
				mat = comb.get_meta("bake_material") as Material
			var data: Array = comb.get_meshes()
			if data.size() >= 2 and data[1] is Mesh:
				var raw: Mesh = data[1] as Mesh
				var mi := MeshInstance3D.new()
				mi.mesh = CraftMeshes.weld_smooth(raw)
				mi.transform = comb.transform
				if mat:
					mi.material_override = mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var parent := comb.get_parent()
				parent.add_child(mi)
				comb.queue_free()
		else:
			_bake_csg_in(c)


func _build_stage() -> void:
	# 参照シート相当のニュートラル灰
	# 参照シート寄りの暖灰（冷たい中性灰で幹がプラスチックに見えるのを避ける）
	# 参照パーツ写真寄りの暖クリーム灰
	RenderingServer.set_default_clear_color(Color(0.92, 0.90, 0.86))

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.90, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.91, 0.88)
	# アンビエント過多だと繊維法線が消える。参照級の柔らかい方向光を残す
	# 参照：高キー柔らか光。深影で粘土がプラスチックに見えるのを避ける
	# アンビエント過多だと樹皮溝・フェルト繊維が消える。参照級の柔らかい方向光を残す
	# 参照スタジオ：柔らか方向光。白飛びしない露出で溝・フェルトを読む
	# 参照スタジオ：柔らか方向光で谷を残す。アンビエントで潰さない
	env.ambient_light_energy = 0.64
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.02
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.88
	env.adjustment_contrast = 0.92
	$WorldEnvironment.environment = env

	var key: DirectionalLight3D = $KeyLight
	key.light_color = Color(1.0, 0.985, 0.94)
	# 参照：左上キーで房の丘と谷を読む
	key.light_energy = 0.74
	key.light_specular = 0.0
	key.shadow_enabled = true
	key.shadow_blur = 6.0
	key.shadow_opacity = 0.10
	key.rotation_degrees = Vector3(-54, -36, 0)

	var fill: DirectionalLight3D = $FillLight
	fill.light_color = Color(0.96, 0.96, 0.97)
	fill.light_energy = 0.42
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-26, 58, 0)

	var rim: DirectionalLight3D = $RimLight
	rim.light_color = Color(0.97, 0.97, 0.98)
	rim.light_energy = 0.18
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
	fm.albedo_color = Color(0.92, 0.90, 0.86)
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
			# 参照シート相当：やや俯瞰で根〜冠を同じ比率で読む
			cam.position = Vector3(0.08, 2.70, 7.8)
			cam.look_at(Vector3(0.0, 1.70, 0.0), Vector3.UP)
			cam.fov = 28.0
		"tree_canopy":
			var canopy := NatureFactory.deciduous_part_canopy()
			hold.add_child(canopy)
			cam.position = Vector3(0.0, 1.15, 4.6)
			cam.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)
			cam.fov = 30.0
		"tree_trunk":
			var trunk := NatureFactory.deciduous_part_trunk()
			hold.add_child(trunk)
			cam.position = Vector3(0.05, 1.35, 5.2)
			cam.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)
			cam.fov = 28.0
		"tree_toes":
			var toes := NatureFactory.deciduous_part_toes()
			hold.add_child(toes)
			cam.position = Vector3(0.10, 0.55, 2.6)
			cam.look_at(Vector3(0.0, 0.18, 0.0), Vector3.UP)
			cam.fov = 32.0
		"cottage":
			var home := NatureFactory.cottage()
			hold.add_child(home)
			home.rotation.y = 0.0
			cam.position = Vector3(0.0, 2.2, 9.5)
			cam.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)
			cam.fov = 32.0
		"traveler":
			var packed: PackedScene = load("res://scenes/player/Player.tscn")
			var p: Node3D = packed.instantiate()
			hold.add_child(p)
			p.position = Vector3(0, 0, 0)
			# 顔はローカル +Z。カメラを +Z 側に置いて正面を撮る
			if p.has_method("set_facing_yaw"):
				p.set_facing_yaw(0.0)
			if p is CharacterBody3D:
				(p as CharacterBody3D).set_physics_process(false)
				(p as CharacterBody3D).set_process(false)
				(p as CharacterBody3D).velocity = Vector3.ZERO
			# MeshRoot が回転する実装なら正面固定
			var mr := p.get_node_or_null("MeshRoot")
			if mr:
				mr.rotation.y = 0.0
			cam.position = Vector3(0.0, 0.95, 5.0)
			cam.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
			cam.fov = 28.0
		_:
			push_warning("AssetBench: unknown subject '%s'" % subject)

	cam.current = true
