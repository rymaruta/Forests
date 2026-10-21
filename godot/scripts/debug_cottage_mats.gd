extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var root := NatureFactory.cottage()
	var greys := 0
	var mats := {}
	for n in _all(root):
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var m = mi.material_override
			if m is StandardMaterial3D:
				var sm := m as StandardMaterial3D
				var c := sm.albedo_color
				var key := "%s sh=%s" % [c, sm.shading_mode]
				mats[key] = mats.get(key, 0) + 1
				if c.r < 0.55 and abs(c.r-c.g) < 0.05:
					greys += 1
			elif m is ShaderMaterial:
				mats["shader:"+str(m.get_shader_parameter("base_color"))] = mats.get("shader:"+str(m.get_shader_parameter("base_color")), 0) + 1
	print("GREY_COUNT ", greys)
	for k in mats:
		print("MAT ", k, " x", mats[k])
	quit(0)
func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
