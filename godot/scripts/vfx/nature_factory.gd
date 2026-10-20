extends RefCounted
class_name NatureFactory
## 自然物を一から組み立てる工場。完成度優先。


static func deciduous_tree(rng: RandomNumberGenerator, backdrop: bool = false) -> Node3D:
	var root := Node3D.new()
	var h := rng.randf_range(2.15, 3.15) * (1.6 if backdrop else 1.0)
	var lean := rng.randf_range(-0.14, 0.14)
	var bark_tint := ForestsPalette.BARK_WARM.lerp(ForestsPalette.BARK_COOL, rng.randf())
	var leaf := ForestsPalette.LEAF_SUN.lerp(Color(0.32, 0.56, 0.3), rng.randf())
	var leaf_dark := ForestsPalette.LEAF_SHADE.lerp(leaf.darkened(0.35), 0.5)

	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h, 0.28 if not backdrop else 0.4, 0.1 if not backdrop else 0.15, 16, lean, 0.055)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	# roots flare pads
	for i in 4:
		var root_pad := MeshInstance3D.new()
		root_pad.mesh = CraftMeshes.uv_sphere(0.16, 6, 8, 0.25, float(i) * 5.0, 0.35)
		root_pad.material_override = VisualKit.bark_shader_material(bark_tint.darkened(0.08))
		var a := float(i) / 4.0 * TAU + rng.randf() * 0.3
		root_pad.position = Vector3(cos(a) * 0.22, 0.04, sin(a) * 0.22)
		root_pad.scale = Vector3(1.4, 0.45, 1.1)
		root.add_child(root_pad)

	# branches
	var bcount := 2 if backdrop else rng.randi_range(4, 6)
	for b in bcount:
		var br := MeshInstance3D.new()
		var blen := rng.randf_range(0.5, 0.95) * (1.2 if backdrop else 1.0)
		br.mesh = CraftMeshes.branch(blen, 0.07, 0.018, 7, rng.randf_range(0.12, 0.32))
		br.material_override = VisualKit.bark_shader_material(bark_tint)
		var ang := float(b) / float(bcount) * TAU + rng.randf() * 0.5
		var by := h * rng.randf_range(0.45, 0.78)
		br.position = Vector3(cos(ang) * 0.1 + lean * (by / h), by, sin(ang) * 0.1)
		br.rotation = Vector3(rng.randf_range(0.55, 1.15), ang, rng.randf_range(-0.25, 0.25))
		root.add_child(br)

		# leaf puff at branch tip
		var puff := MeshInstance3D.new()
		puff.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(0.35, 0.55))
		puff.material_override = VisualKit.foliage_material(leaf, leaf_dark)
		puff.position = Vector3(cos(ang) * blen * 0.7, by + blen * 0.35, sin(ang) * blen * 0.7)
		puff.scale = Vector3.ONE * rng.randf_range(0.7, 1.0)
		root.add_child(puff)

	# main canopy
	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(1.2, 1.6) * (1.4 if backdrop else 1.0))
	canopy.material_override = VisualKit.foliage_material(leaf, leaf_dark)
	canopy.position = Vector3(lean * 0.85, h * 0.9, 0)
	root.add_child(canopy)

	# secondary crown for silhouette richness
	var crown2 := MeshInstance3D.new()
	crown2.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(0.7, 1.0))
	crown2.material_override = VisualKit.foliage_material(leaf.lightened(0.06), leaf_dark)
	crown2.position = Vector3(lean * 0.5 + rng.randf_range(-0.2, 0.2), h * 1.05, rng.randf_range(-0.2, 0.2))
	root.add_child(crown2)

	if not backdrop:
		var cards := MeshInstance3D.new()
		cards.mesh = CraftMeshes.leaf_cards(rng, 28, rng.randf_range(1.0, 1.3))
		cards.material_override = VisualKit.foliage_material(leaf.lightened(0.1), leaf_dark)
		cards.position = canopy.position
		cards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(cards)

	root.set_meta("tree_height", h)
	return root


static func pine_tree(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var h := rng.randf_range(2.6, 3.8)
	var bark_tint := ForestsPalette.BARK_COOL
	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h, 0.2, 0.055, 14, rng.randf_range(-0.06, 0.06), 0.04)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	var layers := rng.randi_range(5, 7)
	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.pine_canopy(layers, rng.randf_range(1.05, 1.45), h * 0.9)
	canopy.material_override = VisualKit.foliage_material(ForestsPalette.PINE, ForestsPalette.PINE_DARK)
	canopy.position.y = 0.25
	root.add_child(canopy)

	# tip needle puff
	var tip := MeshInstance3D.new()
	tip.mesh = CraftMeshes.uv_sphere(0.22, 7, 9, 0.2, rng.randf() * 10.0, 1.2)
	tip.material_override = VisualKit.foliage_material(ForestsPalette.PINE.lightened(0.05), ForestsPalette.PINE_DARK)
	tip.position.y = h * 0.95
	root.add_child(tip)

	root.set_meta("tree_height", h)
	return root


static func flower(rng: RandomNumberGenerator, petal: Color) -> Node3D:
	var root := Node3D.new()
	var stem_h := rng.randf_range(0.38, 0.52)
	var stem := MeshInstance3D.new()
	stem.mesh = CraftMeshes.trunk(stem_h, 0.018, 0.01, 8, rng.randf_range(-0.05, 0.05), 0.0)
	stem.material_override = VisualKit.character_material(Color(0.26, 0.54, 0.3), Color(0.16, 0.36, 0.18))
	root.add_child(stem)

	# leaves on stem
	for side in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.mesh = CraftMeshes.flower_petals(1, rng.randf_range(0.09, 0.12))
		leaf.material_override = VisualKit.character_material(Color(0.32, 0.58, 0.32), Color(0.18, 0.4, 0.2))
		leaf.position = Vector3(0.015 * side, stem_h * 0.4, 0)
		leaf.rotation = Vector3(-0.5, 0.2 * side, 1.0 * side)
		root.add_child(leaf)

	var center := MeshInstance3D.new()
	center.mesh = CraftMeshes.uv_sphere(0.05, 6, 8, 0.1, rng.randf() * 8.0)
	center.position.y = stem_h + 0.02
	var cm := VisualKit.character_material(Color(0.96, 0.84, 0.3), Color(0.8, 0.6, 0.2))
	cm.set_shader_parameter("rim_strength", 0.2)
	center.material_override = cm
	# emission via standard overlay
	var glow := MeshInstance3D.new()
	glow.mesh = CraftMeshes.uv_sphere(0.04, 5, 6)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.98, 0.86, 0.35)
	gm.emission_enabled = true
	gm.emission = Color(0.98, 0.82, 0.3)
	gm.emission_energy_multiplier = 0.4
	glow.material_override = gm
	glow.position.y = stem_h + 0.02
	root.add_child(glow)

	var petals := MeshInstance3D.new()
	petals.mesh = CraftMeshes.flower_petals(rng.randi_range(5, 7), rng.randf_range(0.14, 0.19))
	petals.position.y = stem_h + 0.02
	var pm := StandardMaterial3D.new()
	pm.albedo_color = petal
	pm.roughness = 0.42
	pm.emission_enabled = true
	pm.emission = petal
	pm.emission_energy_multiplier = 0.22
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	petals.material_override = pm
	root.add_child(petals)
	return root


static func cottage() -> Node3D:
	## 手組みの小さな小屋。Forests の拠点シルエット。
	var root := Node3D.new()
	root.name = "Cottage"

	var wall_mat := VisualKit.character_material(Color(0.86, 0.78, 0.62), Color(0.62, 0.52, 0.4))
	var wood := VisualKit.bark_shader_material(Color(0.5, 0.34, 0.2))
	var roof_mat := VisualKit.character_material(Color(0.55, 0.38, 0.28), Color(0.35, 0.22, 0.16))
	roof_mat.set_shader_parameter("rim_strength", 0.08)

	# floor pad
	var floor := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(3.2, 0.12, 2.6)
	floor.mesh = fm
	floor.material_override = VisualKit.character_material(Color(0.55, 0.42, 0.28), Color(0.35, 0.26, 0.16))
	floor.position.y = 0.06
	root.add_child(floor)

	# walls as soft boxes with slight bevel feel via scale
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.8, 1.7, 2.2)
	body.mesh = bm
	body.material_override = wall_mat
	body.position.y = 0.95
	root.add_child(body)

	# roof prism via two wedges approximated with scaled boxes + peak
	var roof_l := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(3.2, 0.14, 1.5)
	roof_l.mesh = rm
	roof_l.material_override = roof_mat
	roof_l.position = Vector3(0, 2.05, -0.35)
	roof_l.rotation_degrees.x = -32
	root.add_child(roof_l)
	var roof_r := MeshInstance3D.new()
	roof_r.mesh = rm.duplicate()
	roof_r.material_override = roof_mat
	roof_r.position = Vector3(0, 2.05, 0.35)
	roof_r.rotation_degrees.x = 32
	root.add_child(roof_r)

	# ridge
	var ridge := MeshInstance3D.new()
	var ridgem := BoxMesh.new()
	ridgem.size = Vector3(3.25, 0.1, 0.18)
	ridge.mesh = ridgem
	ridge.material_override = wood
	ridge.position.y = 2.45
	root.add_child(ridge)

	# door
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.7, 1.15, 0.08)
	door.mesh = dm
	door.material_override = wood
	door.position = Vector3(0, 0.7, 1.12)
	root.add_child(door)

	# windows
	for side in [-1.0, 1.0]:
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(0.45, 0.45, 0.06)
		win.mesh = wm
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.7, 0.88, 0.95)
		wmat.emission_enabled = true
		wmat.emission = Color(0.85, 0.95, 1.0)
		wmat.emission_energy_multiplier = 0.35
		wmat.roughness = 0.2
		win.material_override = wmat
		win.position = Vector3(side * 0.85, 1.15, 1.12)
		root.add_child(win)

	# chimney
	var chim := MeshInstance3D.new()
	chim.mesh = CraftMeshes.trunk(0.55, 0.14, 0.12, 8)
	chim.material_override = VisualKit.character_material(Color(0.55, 0.42, 0.36), Color(0.35, 0.26, 0.22))
	chim.position = Vector3(0.85, 2.35, -0.2)
	root.add_child(chim)

	# porch step
	var step := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.0, 0.12, 0.4)
	step.mesh = sm
	step.material_override = wood
	step.position = Vector3(0, 0.12, 1.4)
	root.add_child(step)

	# flower boxes under windows
	for side in [-1.0, 1.0]:
		var box := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.55, 0.18, 0.22)
		box.mesh = bx
		box.material_override = wood
		box.position = Vector3(side * 0.85, 0.85, 1.2)
		root.add_child(box)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(80 + side * 10)
		for j in 3:
			var f := flower(rng, ForestsPalette.petals()[j % 6])
			f.scale = Vector3.ONE * 0.55
			f.position = Vector3(side * 0.85 + (j - 1) * 0.12, 0.95, 1.2)
			root.add_child(f)

	return root
