extends RefCounted
class_name VisualKit
## Forests 手組みマテリアル基盤。


static func load_shader(path: String) -> Shader:
	return load(path) as Shader


static func terrain_material() -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_terrain.gdshader")
	m.set_shader_parameter("grass_tex", load("res://assets/textures/grass.png"))
	m.set_shader_parameter("dirt_tex", load("res://assets/textures/dirt.png"))
	# さらに落ち着いた緑（ネオンを殺す）
	m.set_shader_parameter("tint", Vector3(0.55, 0.62, 0.4))
	return m


static func foliage_material(color: Color, dark: Color = Color.BLACK) -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_foliage.gdshader")
	m.set_shader_parameter("leaf_tex", load("res://assets/textures/leaf.png"))
	m.set_shader_parameter("leaf_n_tex", load("res://assets/textures/leaf_n.png"))
	m.set_shader_parameter("leaf_color", Vector3(color.r, color.g, color.b))
	var dcol := dark if (dark.a > 0.01 and dark != Color.BLACK) else color.darkened(0.38)
	m.set_shader_parameter("leaf_dark", Vector3(dcol.r, dcol.g, dcol.b))
	m.set_shader_parameter("wind_strength", 0.008)
	m.set_shader_parameter("roughness_val", 1.0)
	m.set_shader_parameter("flock_mix", 0.99)
	m.set_shader_parameter("nap_scale", 42.0)
	m.set_shader_parameter("nap_strength", 1.55)
	# 縁アルファ柔縁を確実にブレンド
	m.render_priority = 1
	return m


static func flock_shell_material(color: Color, density: float = 0.42) -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_flock_shell.gdshader")
	m.set_shader_parameter("leaf_tex", load("res://assets/textures/leaf.png"))
	m.set_shader_parameter("leaf_color", Vector3(color.r, color.g, color.b))
	m.set_shader_parameter("density", density)
	# 白縁防止：本体よりわずかに暗い葉色のみ
	m.set_shader_parameter("shell_tint", 0.92)
	return m


static func water_material() -> Material:
	# 半透明は環境によって白飛びするので、不透明の澄んだ青緑
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.52, 0.56, 1.0)
	m.roughness = 0.22
	m.metallic = 0.1
	m.emission_enabled = true
	m.emission = Color(0.08, 0.32, 0.38)
	m.emission_energy_multiplier = 0.14
	return m


static func grass_material() -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_grass.gdshader")
	m.set_shader_parameter("tip_color", Vector3(0.5, 0.64, 0.34))
	m.set_shader_parameter("root_color", Vector3(0.28, 0.4, 0.24))
	return m


static func stone_material(tint: Color = ForestsPalette.STONE) -> Material:
	return character_material(tint, tint.darkened(0.28).lerp(ForestsPalette.STONE_MOSS, 0.35))


static func plaster_material() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.86, 0.76)
	m.albedo_texture = load("res://assets/textures/plaster.png")
	m.uv1_scale = Vector3(3.2, 3.2, 3.2)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.roughness = 0.98
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func roof_tile_material() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.88, 0.55, 0.38)
	m.albedo_texture = load("res://assets/textures/roof_tile.png")
	m.uv1_scale = Vector3(2.2, 2.2, 2.2)
	m.uv1_triplanar = true
	m.roughness = 0.92
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func bark_material(tint: Color = ForestsPalette.BARK_WARM) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = load("res://assets/textures/bark.png")
	m.uv1_scale = Vector3(1.5, 2.5, 1.0)
	m.roughness = 0.88
	return m


static func bark_shader_material(tint: Color = ForestsPalette.BARK_WARM) -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_bark.gdshader")
	m.set_shader_parameter("bark_tex", load("res://assets/textures/bark.png"))
	m.set_shader_parameter("bark_color", Vector3(tint.r, tint.g, tint.b))
	# 溝が読めるよう暗部をしっかり落とす（ただしゼブラ帯にはしない）
	var bd := tint.darkened(0.44)
	m.set_shader_parameter("bark_dark", Vector3(bd.r, bd.g, bd.b))
	# 刷毛筋は細かく、コントラストはシェーダ側で抑える
	m.set_shader_parameter("uv_scale_x", 1.10)
	m.set_shader_parameter("uv_scale_y", 1.85)
	m.set_shader_parameter("flock_mix", 0.80)
	m.set_shader_parameter("nap_scale", 3.6)
	return m


static func character_material(base: Color, shadow: Color = Color.BLACK) -> Material:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_character.gdshader")
	m.set_shader_parameter("base_color", Vector3(base.r, base.g, base.b))
	if shadow == Color.BLACK:
		shadow = base.darkened(0.4)
	m.set_shader_parameter("shadow_color", Vector3(shadow.r, shadow.g, shadow.b))
	return m


static func make_height_terrain(size: float = 52.0, res: int = 48) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var step := size / float(res)
	for z in res:
		for x in res:
			var x0 := -half + x * step
			var z0 := -half + z * step
			var x1 := x0 + step
			var z1 := z0 + step
			_add_v(st, Vector3(x0, _h(x0, z0), z0))
			_add_v(st, Vector3(x1, _h(x1, z0), z0))
			_add_v(st, Vector3(x0, _h(x0, z1), z1))
			_add_v(st, Vector3(x1, _h(x1, z0), z0))
			_add_v(st, Vector3(x1, _h(x1, z1), z1))
			_add_v(st, Vector3(x0, _h(x0, z1), z1))
	st.generate_normals()
	return st.commit()


static func _h(x: float, z: float) -> float:
	var d := sqrt(x * x + z * z)
	var flatten := smoothstep(3.2, 9.5, d)
	var n := sin(x * 0.09) * cos(z * 0.08) * 1.35
	n += sin(x * 0.19 + 1.7) * cos(z * 0.16) * 0.7
	n += sin(x * 0.37) * 0.25
	n += sin(x * 0.55 + z * 0.4) * 0.12
	var pond := Vector2(x - 8.0, z + 6.0).length()
	if pond < 5.5:
		n = lerp(n, -0.55, 1.0 - pond / 5.5)
	var home := Vector2(x + 6.0, z - 4.0).length()
	if home < 4.0:
		n = lerp(n, 0.05, 1.0 - home / 4.0)
	return n * flatten


static func _add_v(st: SurfaceTool, p: Vector3) -> void:
	st.set_uv(Vector2(p.x, p.z) * 0.045)
	st.add_vertex(p)
