extends RefCounted
class_name VisualKit
## 共通マテリアル / メッシュ生成（スタイライズド見た目）


static func load_shader(path: String) -> Shader:
	return load(path) as Shader


static func terrain_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_terrain.gdshader")
	m.set_shader_parameter("grass_tex", load("res://assets/textures/grass.png"))
	m.set_shader_parameter("dirt_tex", load("res://assets/textures/dirt.png"))
	return m


static func foliage_material(color: Color, dark: Color = Color.BLACK) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_foliage.gdshader")
	m.set_shader_parameter("leaf_tex", load("res://assets/textures/leaf.png"))
	m.set_shader_parameter("leaf_color", color)
	if dark.a > 0.01 and dark != Color.BLACK:
		m.set_shader_parameter("leaf_dark", dark)
	else:
		m.set_shader_parameter("leaf_dark", color.darkened(0.35))
	m.set_shader_parameter("wind_strength", 0.1)
	return m


static func water_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_water.gdshader")
	return m


static func grass_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load_shader("res://assets/shaders/stylized_grass.gdshader")
	return m


static func bark_material(tint: Color = Color(0.42, 0.28, 0.18)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = load("res://assets/textures/bark.png")
	m.uv1_scale = Vector3(1.5, 2.5, 1.0)
	m.roughness = 0.88
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
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
			var y00 := _h(x0, z0)
			var y10 := _h(x1, z0)
			var y01 := _h(x0, z1)
			var y11 := _h(x1, z1)
			# tri 1
			_add_v(st, Vector3(x0, y00, z0))
			_add_v(st, Vector3(x1, y10, z0))
			_add_v(st, Vector3(x0, y01, z1))
			# tri 2
			_add_v(st, Vector3(x1, y10, z0))
			_add_v(st, Vector3(x1, y11, z1))
			_add_v(st, Vector3(x0, y01, z1))
	st.generate_normals()
	return st.commit()


static func _h(x: float, z: float) -> float:
	# はっきりわかる起伏（スポーン付近は平坦）
	var d := sqrt(x * x + z * z)
	var flatten := smoothstep(3.5, 10.0, d)
	var n := sin(x * 0.09) * cos(z * 0.08) * 1.35
	n += sin(x * 0.19 + 1.7) * cos(z * 0.16) * 0.7
	n += sin(x * 0.37) * 0.25
	# pond basin
	var pond := Vector2(x - 8.0, z + 6.0).length()
	if pond < 5.5:
		n = lerp(n, -0.55, 1.0 - pond / 5.5)
	return n * flatten


static func _add_v(st: SurfaceTool, p: Vector3) -> void:
	st.set_uv(Vector2(p.x, p.z) * 0.05)
	st.add_vertex(p)


static func make_grass_blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# simple blade: two quads crossed, vertex color = height
	var h := 0.55
	var w := 0.06
	_blade_quad(st, w, h, 0.0)
	_blade_quad(st, w, h, PI * 0.5)
	st.generate_normals()
	return st.commit()


static func _blade_quad(st: SurfaceTool, w: float, h: float, yaw: float) -> void:
	var c := cos(yaw)
	var s := sin(yaw)
	var p0 := Vector3(-w * c, 0.0, -w * s)
	var p1 := Vector3(w * c, 0.0, w * s)
	var p2 := Vector3(w * 0.3 * c, h, w * 0.3 * s)
	var p3 := Vector3(-w * 0.3 * c, h, -w * 0.3 * s)
	_colored(st, p0, 0.0)
	_colored(st, p1, 0.0)
	_colored(st, p2, 1.0)
	_colored(st, p0, 0.0)
	_colored(st, p2, 1.0)
	_colored(st, p3, 1.0)


static func _colored(st: SurfaceTool, p: Vector3, height_mask: float) -> void:
	st.set_color(Color(height_mask, height_mask, height_mask))
	st.add_vertex(p)


static func make_canopy_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	## organic blob from several overlapping spheres merged as separate surfaces... 
	## For simplicity return null and use multi MeshInstance instead.
	return null
