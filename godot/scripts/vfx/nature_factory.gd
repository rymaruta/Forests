extends RefCounted
class_name NatureFactory
## 自然物工場。房状樹冠・厚み花・読みやすい小屋。


static func deciduous_tree(rng: RandomNumberGenerator, backdrop: bool = false) -> Node3D:
	var root := Node3D.new()
	var h := rng.randf_range(2.35, 3.15) * (1.55 if backdrop else 1.0)
	var lean := rng.randf_range(-0.1, 0.1)
	var bark_tint := ForestsPalette.BARK_WARM.lerp(ForestsPalette.BARK_COOL, rng.randf())
	var leaf := ForestsPalette.LEAF_SUN.lerp(Color(0.34, 0.5, 0.28), rng.randf())
	var leaf_dark := ForestsPalette.LEAF_SHADE.lerp(leaf.darkened(0.2), 0.35)

	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h, 0.3 if not backdrop else 0.4, 0.11 if not backdrop else 0.15, 16, lean, 0.06)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	# 根元は厚めの盛り上がり（平たい黒円盤にしない）
	for i in 3:
		var root_pad := MeshInstance3D.new()
		root_pad.mesh = CraftMeshes.uv_sphere(0.18, 6, 8, 0.18, float(i) * 4.0, 0.55)
		root_pad.material_override = VisualKit.bark_shader_material(bark_tint.darkened(0.06))
		var a := float(i) / 3.0 * TAU + 0.25
		root_pad.position = Vector3(cos(a) * 0.18, 0.08, sin(a) * 0.18)
		root_pad.scale = Vector3(1.2, 0.7, 1.0)
		root_pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(root_pad)

	var bcount := 3 if backdrop else rng.randi_range(4, 5)
	for b in bcount:
		var br := MeshInstance3D.new()
		var blen := rng.randf_range(0.5, 0.9) * (1.1 if backdrop else 1.0)
		br.mesh = CraftMeshes.branch(blen, 0.065, 0.018, 7, rng.randf_range(0.12, 0.3))
		br.material_override = VisualKit.bark_shader_material(bark_tint)
		var ang := float(b) / float(bcount) * TAU + rng.randf() * 0.3
		var by := h * rng.randf_range(0.5, 0.78)
		br.position = Vector3(cos(ang) * 0.12 + lean * 0.5, by, sin(ang) * 0.12)
		br.rotation = Vector3(rng.randf_range(0.5, 1.0), ang, rng.randf_range(-0.2, 0.2))
		root.add_child(br)

		var puff := MeshInstance3D.new()
		puff.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(0.4, 0.58))
		puff.material_override = VisualKit.foliage_material(leaf.lerp(leaf.lightened(0.06), rng.randf()), leaf_dark)
		puff.position = Vector3(cos(ang) * blen * 0.62 + lean * 0.25, by + blen * 0.38, sin(ang) * blen * 0.62)
		puff.scale = Vector3.ONE * rng.randf_range(0.8, 1.1)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(puff)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(1.25, 1.55) * (1.35 if backdrop else 1.0))
	canopy.material_override = VisualKit.foliage_material(leaf, leaf_dark)
	canopy.position = Vector3(lean * 0.65, h * 0.84, 0)
	# 球状樹冠の影は地面に黒い円盤になるので切る
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)

	var crown2 := MeshInstance3D.new()
	crown2.mesh = CraftMeshes.canopy_volume(rng, rng.randf_range(0.7, 0.95))
	crown2.material_override = VisualKit.foliage_material(leaf.lightened(0.04), leaf_dark)
	crown2.position = Vector3(lean * 0.35 + rng.randf_range(-0.12, 0.12), h * 1.05, rng.randf_range(-0.12, 0.12))
	crown2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(crown2)

	root.set_meta("tree_height", h)
	return root


static func pine_tree(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var h := rng.randf_range(2.7, 3.6)
	var bark_tint := ForestsPalette.BARK_COOL
	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h, 0.2, 0.055, 12, rng.randf_range(-0.05, 0.05), 0.04)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.pine_canopy(rng.randi_range(5, 6), rng.randf_range(1.05, 1.35), h * 0.9)
	canopy.material_override = VisualKit.foliage_material(ForestsPalette.PINE, ForestsPalette.PINE_DARK)
	canopy.position.y = 0.18
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)

	root.set_meta("tree_height", h)
	return root


static func flower(rng: RandomNumberGenerator, petal: Color) -> Node3D:
	var root := Node3D.new()
	var stem_h := rng.randf_range(0.34, 0.46)
	var stem := MeshInstance3D.new()
	stem.mesh = CraftMeshes.trunk(stem_h, 0.016, 0.01, 7, rng.randf_range(-0.04, 0.04), 0.0)
	stem.material_override = VisualKit.character_material(Color(0.3, 0.5, 0.3), Color(0.18, 0.34, 0.18))
	stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stem)

	for side in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.mesh = CraftMeshes.flower_leaf(rng.randf_range(0.07, 0.1), rng.randf() * 10.0)
		leaf.material_override = VisualKit.character_material(Color(0.32, 0.52, 0.3), Color(0.18, 0.34, 0.18))
		leaf.position = Vector3(0.04 * side, stem_h * 0.4, 0)
		leaf.rotation = Vector3(-0.35, 0.1 * side, 0.85 * side)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(leaf)

	var glow := MeshInstance3D.new()
	glow.mesh = CraftMeshes.uv_sphere(0.05, 6, 8, 0.06, rng.randf() * 8.0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.92, 0.8, 0.35)
	gm.emission_enabled = true
	gm.emission = Color(0.9, 0.75, 0.28)
	gm.emission_energy_multiplier = 0.22
	glow.material_override = gm
	glow.position.y = stem_h + 0.03
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glow)

	var petals := MeshInstance3D.new()
	petals.mesh = CraftMeshes.flower_petals(rng.randi_range(5, 6), rng.randf_range(0.11, 0.15))
	petals.position.y = stem_h + 0.02
	petals.material_override = VisualKit.character_material(petal, petal.darkened(0.22))
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(petals)
	return root


static func cottage() -> Node3D:
	## 漆喰壁が主役。梁は枠だけ。屋根はシンプルな二面。
	var root := Node3D.new()
	root.name = "Cottage"

	var wall := VisualKit.character_material(ForestsPalette.PLASTER, Color(0.62, 0.56, 0.46))
	var wood := VisualKit.bark_shader_material(ForestsPalette.TIMBER)
	var roof := VisualKit.character_material(ForestsPalette.ROOF_TILE, ForestsPalette.ROOF_SHADOW)
	var stone := VisualKit.character_material(Color(0.5, 0.48, 0.44), Color(0.34, 0.34, 0.3))

	# 石基壇
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(3.4, 0.32, 2.8)
	plinth.mesh = pm
	plinth.material_override = stone
	plinth.position.y = 0.16
	root.add_child(plinth)

	# 漆喰本体
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.9, 1.65, 2.25)
	body.mesh = bm
	body.material_override = wall
	body.position.y = 1.1
	root.add_child(body)

	# 前面の枠梁のみ（壁を埋め尽くさない）
	_beam(root, wood, Vector3(-1.42, 1.1, 1.15), Vector3(0.09, 1.65, 0.07))
	_beam(root, wood, Vector3(1.42, 1.1, 1.15), Vector3(0.09, 1.65, 0.07))
	_beam(root, wood, Vector3(0, 0.35, 1.15), Vector3(2.9, 0.09, 0.07))
	_beam(root, wood, Vector3(0, 1.85, 1.15), Vector3(2.9, 0.09, 0.07))
	_beam(root, wood, Vector3(0, 1.1, 1.15), Vector3(0.09, 1.55, 0.07))
	# 斜め梁は前面パネル内に収める
	var diag := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.2, 0.08, 0.05)
	diag.mesh = dm
	diag.material_override = wood
	diag.position = Vector3(-0.7, 1.1, 1.16)
	diag.rotation_degrees.z = 32
	root.add_child(diag)
	var diag2 := diag.duplicate() as MeshInstance3D
	diag2.position = Vector3(0.7, 1.1, 1.16)
	diag2.rotation_degrees.z = -32
	root.add_child(diag2)

	# 側面は角柱だけ
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.48, 1.1, -1.05), Vector3(0.08, 1.65, 0.08))
		_beam(root, wood, Vector3(side * 1.48, 1.1, 1.05), Vector3(0.08, 1.65, 0.08))
		_beam(root, wood, Vector3(side * 1.48, 0.35, 0), Vector3(0.08, 0.09, 2.2))
		_beam(root, wood, Vector3(side * 1.48, 1.85, 0), Vector3(0.08, 0.09, 2.2))

	# 屋根二面（厚い板）
	var roof_l := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(3.35, 0.14, 1.55)
	roof_l.mesh = rm
	roof_l.material_override = roof
	roof_l.position = Vector3(0, 2.18, -0.42)
	roof_l.rotation_degrees.x = -34
	root.add_child(roof_l)
	var roof_r := MeshInstance3D.new()
	roof_r.mesh = rm.duplicate()
	roof_r.material_override = roof
	roof_r.position = Vector3(0, 2.18, 0.42)
	roof_r.rotation_degrees.x = 34
	root.add_child(roof_r)
	# 瓦の段差（見た目の厚み）
	for i in 4:
		var tile := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(3.2, 0.04, 0.28)
		tile.mesh = tm
		tile.material_override = VisualKit.character_material(
			ForestsPalette.ROOF_TILE.darkened(0.04 * float(i % 2)),
			ForestsPalette.ROOF_SHADOW
		)
		var t := float(i) / 3.0
		tile.position = Vector3(0, 2.05 + t * 0.35, 0.55 - t * 0.55)
		tile.rotation_degrees.x = 34
		root.add_child(tile)
		var tile2 := tile.duplicate() as MeshInstance3D
		tile2.position = Vector3(0, 2.05 + t * 0.35, -0.55 + t * 0.55)
		tile2.rotation_degrees.x = -34
		root.add_child(tile2)

	var ridge := MeshInstance3D.new()
	var ridgem := BoxMesh.new()
	ridgem.size = Vector3(3.4, 0.12, 0.18)
	ridge.mesh = ridgem
	ridge.material_override = wood
	ridge.position.y = 2.52
	root.add_child(ridge)

	# 破風
	for side in [-1.0, 1.0]:
		var gable := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.1, 0.9, 2.3)
		gable.mesh = gm
		gable.material_override = wall
		gable.position = Vector3(side * 1.45, 1.95, 0)
		root.add_child(gable)

	# ポーチ柱
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = CraftMeshes.trunk(1.1, 0.065, 0.05, 8)
		post.material_override = wood
		post.position = Vector3(side * 0.65, 0.3, 1.48)
		root.add_child(post)
	_beam(root, wood, Vector3(0, 1.38, 1.48), Vector3(1.45, 0.1, 0.1))

	# ドア
	var door := MeshInstance3D.new()
	var doorm := BoxMesh.new()
	doorm.size = Vector3(0.68, 1.12, 0.08)
	door.mesh = doorm
	door.material_override = wood
	door.position = Vector3(0, 0.88, 1.16)
	root.add_child(door)
	_beam(root, VisualKit.bark_shader_material(ForestsPalette.TIMBER.darkened(0.12)), Vector3(-0.16, 0.88, 1.21), Vector3(0.035, 1.0, 0.02))
	_beam(root, VisualKit.bark_shader_material(ForestsPalette.TIMBER.darkened(0.12)), Vector3(0.16, 0.88, 1.21), Vector3(0.035, 1.0, 0.02))
	var knob := MeshInstance3D.new()
	knob.mesh = CraftMeshes.uv_sphere(0.036, 5, 6)
	knob.material_override = VisualKit.character_material(Color(0.78, 0.62, 0.32), Color(0.48, 0.36, 0.16))
	knob.position = Vector3(0.22, 0.82, 1.22)
	root.add_child(knob)

	# 窓
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 0.95, 1.28, 1.16), Vector3(0.56, 0.56, 0.08))
		var glass := MeshInstance3D.new()
		var glm := BoxMesh.new()
		glm.size = Vector3(0.42, 0.42, 0.04)
		glass.mesh = glm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.72, 0.88, 0.94)
		gmat.emission_enabled = true
		gmat.emission = Color(0.88, 0.94, 0.98)
		gmat.emission_energy_multiplier = 0.32
		gmat.roughness = 0.2
		glass.material_override = gmat
		glass.position = Vector3(side * 0.95, 1.28, 1.2)
		root.add_child(glass)
		_beam(root, wood, Vector3(side * 0.95, 1.28, 1.22), Vector3(0.42, 0.04, 0.02))
		_beam(root, wood, Vector3(side * 0.95, 1.28, 1.22), Vector3(0.04, 0.42, 0.02))

	# 煙突
	var chim := MeshInstance3D.new()
	var chim_m := BoxMesh.new()
	chim_m.size = Vector3(0.36, 0.8, 0.36)
	chim.mesh = chim_m
	chim.material_override = stone
	chim.position = Vector3(0.9, 2.55, -0.35)
	root.add_child(chim)
	_beam(root, stone, Vector3(0.9, 2.98, -0.35), Vector3(0.44, 0.08, 0.44))

	# 段
	_beam(root, wood, Vector3(0, 0.22, 1.48), Vector3(1.15, 0.12, 0.48))
	_beam(root, wood, Vector3(0, 0.12, 1.65), Vector3(0.95, 0.1, 0.36))

	# 花箱
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 0.95, 0.92, 1.24), Vector3(0.58, 0.15, 0.22))
		for j in 2:
			var f := flower(rng, ForestsPalette.petals()[j % 6])
			f.scale = Vector3.ONE * 0.48
			f.position = Vector3(side * 0.95 + (j - 0.5) * 0.14, 1.0, 1.24)
			root.add_child(f)

	return root


static func _beam(root: Node3D, mat: Material, pos: Vector3, size: Vector3) -> void:
	var t := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	t.mesh = m
	t.material_override = mat
	t.position = pos
	root.add_child(t)
