extends RefCounted
class_name VisualKit
## Forests 手組みマテリアル基盤。


static func load_shader(path: String) -> Shader:
	return load(path) as Shader


static func terrain_material() -> Material:
	# Web 安定優先: まずは StandardMaterial（シェーダー障害切り分け）
	var m := StandardMaterial3D.new()
	m.albedo_color = ForestsPalette.GRASS_B
	m.albedo_texture = load("res://assets/textures/grass.png")
	m.uv1_scale = Vector3(8, 8, 8)
	m.roughness = 0.92
	return m


static func foliage_material(color: Color, dark: Color = Color.BLACK) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = load("res://assets/textures/leaf.png")
	m.roughness = 0.7
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func water_material() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(ForestsPalette.WATER_SHALLOW.r, ForestsPalette.WATER_SHALLOW.g, ForestsPalette.WATER_SHALLOW.b, 0.82)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic = 0.15
	return m


static func grass_material() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.68, 0.32)
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	return m


static func bark_material(tint: Color = ForestsPalette.BARK_WARM) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = load("res://assets/textures/bark.png")
	m.uv1_scale = Vector3(1.5, 2.5, 1.0)
	m.roughness = 0.88
	return m


static func bark_shader_material(tint: Color = ForestsPalette.BARK_WARM) -> Material:
	return bark_material(tint)


static func character_material(base: Color, shadow: Color = Color.BLACK) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = 0.7
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
	# cottage terrace flatten near (-6, 4)
	var home := Vector2(x + 6.0, z - 4.0).length()
	if home < 4.0:
		n = lerp(n, 0.05, 1.0 - home / 4.0)
	return n * flatten


static func _add_v(st: SurfaceTool, p: Vector3) -> void:
	st.set_uv(Vector2(p.x, p.z) * 0.045)
	st.add_vertex(p)
