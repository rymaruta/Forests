extends RefCounted
class_name NatureFactory
## 参照シート準拠。闇雲に増やさず、目標形に合わせる。
## TREE: ref-tree-deciduous.jpg — 太い幹・根の指・短い枝・フェルト雲冠


## ヒーロー樹の固定比率（参照 ref-tree-deciduous.jpg）
## 幹高 : 樹冠幅 : 根幅  ≈  2.0 : 3.2 : 1.2  （幹は太く短め、冠は横広）
const HERO_TRUNK_H := 1.75
const HERO_BASE_R := 0.40
const HERO_TOP_R := 0.18
const HERO_CANOPY_R := 1.28
const HERO_SEED := 2901


static func deciduous_tree_hero(rng: RandomNumberGenerator = null) -> Node3D:
	## Bench合格用。毎回ランダム禁止。比率・シード固定。
	var r := rng if rng != null else RandomNumberGenerator.new()
	r.seed = HERO_SEED
	return _deciduous_build(r, false, true)


static func deciduous_tree(rng: RandomNumberGenerator, backdrop: bool = false) -> Node3D:
	## ワールド用。ヒーローと同製法、軽いばらつきのみ。
	return _deciduous_build(rng, backdrop, false)


static func _deciduous_build(rng: RandomNumberGenerator, backdrop: bool, hero: bool) -> Node3D:
	## 参照: 厚幹＋根の指＋左右の短い枝＋重なるフェルト雲房
	var root := Node3D.new()
	var h: float
	var lean: float
	var base_r: float
	var top_r: float
	var canopy_r: float
	if hero:
		h = HERO_TRUNK_H
		lean = 0.02
		base_r = HERO_BASE_R
		top_r = HERO_TOP_R
		canopy_r = HERO_CANOPY_R
	else:
		h = rng.randf_range(2.35, 2.85) * (1.55 if backdrop else 1.0)
		lean = rng.randf_range(-0.06, 0.06)
		base_r = (0.38 if not backdrop else 0.5)
		top_r = (0.14 if not backdrop else 0.2)
		canopy_r = rng.randf_range(1.35, 1.55) * (1.4 if backdrop else 1.0)

	var bark_tint := Color(0.36, 0.24, 0.15) if hero else ForestsPalette.BARK_WARM.lerp(Color(0.40, 0.26, 0.16), rng.randf() * 0.5)
	# セージ／オリーブ（参照：くすみ・ホットスポット禁止）
	var leaf := Color(0.46, 0.50, 0.40) if hero else Color(0.4, 0.48, 0.35).lerp(Color(0.36, 0.44, 0.32), rng.randf())
	var leaf_dark := Color(0.34, 0.38, 0.30)

	# 幹は一本の CraftMeshes（MC幹は趾接合で白欠けが出るので使わない）
	var trunk_h := h * (1.05 if hero else 0.92)
	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(
		trunk_h, base_r, top_r,
		32 if hero else 16, lean,
		0.055 if hero else 0.028, true,
		0
	)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)
	var toe_n := 4 if hero else (0 if backdrop else 4)
	for i in toe_n:
		var a := float(i) / float(toe_n) * TAU + 0.55
		# 丸い粘土趾（板状・尖り禁止）。幹に埋めつつ外へ
		var toe_r := 0.26 if hero else 0.16
		var toe := MeshInstance3D.new()
		toe.mesh = CraftMeshes.uv_sphere(toe_r, 14 if hero else 10, 16 if hero else 12, 0.012, float(i) * 2.7, 0.88)
		toe.material_override = VisualKit.bark_shader_material(bark_tint)
		# フレア外縁のすぐ外。丸く接地（板状・白欠け禁止）
		var reach := (base_r * 1.18) if hero else (base_r + 0.08)
		toe.position = Vector3(cos(a) * reach, toe_r * 0.92, sin(a) * reach)
		toe.scale = Vector3(1.15, 1.0, 1.1)
		toe.rotation = Vector3(0.12, a, 0.0)
		toe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(toe)
		if hero:
			var join := MeshInstance3D.new()
			join.mesh = CraftMeshes.uv_sphere(0.18, 12, 14, 0.008, float(i) * 1.7, 0.9)
			join.material_override = VisualKit.bark_shader_material(bark_tint)
			join.position = Vector3(cos(a) * (base_r * 0.40), 0.24, sin(a) * (base_r * 0.40))
			join.scale = Vector3(1.15, 1.0, 1.1)
			join.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(join)

	# 短い Y 枝（ヒーローは冠にほぼ埋めて突き出しを抑える）
	if not hero:
		for b in 2:
			var br := MeshInstance3D.new()
			var blen := rng.randf_range(0.35, 0.5)
			br.mesh = CraftMeshes.branch(blen, 0.06, 0.022, 12, 0.05)
			br.material_override = VisualKit.bark_shader_material(bark_tint)
			var ang := (0.5 if b == 0 else PI - 0.5) + lean * 1.5
			var by := h * (0.58 if b == 0 else 0.54)
			br.position = Vector3(cos(ang) * 0.2 + lean * 0.15, by, 0.06 if b == 0 else -0.05)
			br.rotation = Vector3(1.05, ang, 0.06 if b == 0 else -0.06)
			root.add_child(br)
	else:
		for b in 2:
			var br := MeshInstance3D.new()
			br.mesh = CraftMeshes.branch(0.32, 0.11, 0.05, 12, 0.04)
			br.material_override = VisualKit.bark_shader_material(bark_tint)
			var ang := (0.55 if b == 0 else PI - 0.55)
			br.position = Vector3(cos(ang) * 0.20, h * 0.72, 0.0)
			br.rotation = Vector3(1.15, ang, 0.0)
			root.add_child(br)

	# 雲冠：ヒーローは事前生成の高解像ソフトユニオンOBJ
	var canopy := MeshInstance3D.new()
	if hero and ResourceLoader.exists("res://assets/meshes/canopy_hero.obj"):
		canopy.mesh = load("res://assets/meshes/canopy_hero.obj") as Mesh
	if canopy.mesh == null:
		canopy.mesh = CraftMeshes.canopy_soft_union(rng, canopy_r)
	canopy.material_override = VisualKit.foliage_material(leaf, leaf_dark)
	canopy.position = Vector3(lean * 0.08, h * 0.78, 0.0)
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)

	root.set_meta("tree_height", h)
	root.set_meta("hero", hero)
	return root


static func pine_tree(rng: RandomNumberGenerator) -> Node3D:
	## 針葉は場面用。広葉の参照を邪魔しないよう控えめに。
	var root := Node3D.new()
	var h := rng.randf_range(2.6, 3.3)
	var bark_tint := ForestsPalette.BARK_COOL
	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h, 0.18, 0.05, 12, rng.randf_range(-0.04, 0.04), 0.035)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	var canopy := MeshInstance3D.new()
	canopy.mesh = CraftMeshes.pine_canopy(5, rng.randf_range(0.95, 1.2), h * 0.88)
	canopy.material_override = VisualKit.foliage_material(Color(0.3, 0.42, 0.3), Color(0.18, 0.28, 0.18))
	canopy.position.y = 0.15
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)

	root.set_meta("tree_height", h)
	return root


static func flower(rng: RandomNumberGenerator, petal: Color) -> Node3D:
	var root := Node3D.new()
	var stem_h := rng.randf_range(0.3, 0.4)
	var stem := MeshInstance3D.new()
	stem.mesh = CraftMeshes.trunk(stem_h, 0.014, 0.01, 6, rng.randf_range(-0.03, 0.03), 0.0)
	stem.material_override = VisualKit.character_material(Color(0.32, 0.5, 0.3), Color(0.2, 0.34, 0.18))
	stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stem)

	for side in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.mesh = CraftMeshes.flower_leaf(rng.randf_range(0.06, 0.085), rng.randf() * 10.0)
		leaf.material_override = VisualKit.character_material(Color(0.34, 0.52, 0.3), Color(0.2, 0.34, 0.18))
		leaf.position = Vector3(0.03 * side, stem_h * 0.4, 0)
		leaf.rotation = Vector3(-0.3, 0.1 * side, 0.85 * side)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(leaf)

	var glow := MeshInstance3D.new()
	glow.mesh = CraftMeshes.uv_sphere(0.045, 6, 8, 0.04, rng.randf() * 8.0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.92, 0.8, 0.35)
	gm.emission_enabled = true
	gm.emission = Color(0.9, 0.75, 0.28)
	gm.emission_energy_multiplier = 0.18
	glow.material_override = gm
	glow.position.y = stem_h + 0.025
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glow)

	var petals := MeshInstance3D.new()
	petals.mesh = CraftMeshes.flower_petals(6, rng.randf_range(0.1, 0.13))
	petals.position.y = stem_h + 0.015
	petals.material_override = VisualKit.character_material(petal, petal.darkened(0.18))
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(petals)
	return root


static func cottage() -> Node3D:
	## 参照: ref-cottage.jpg — 漆喰＋太い梁・瓦屋根・石積み・ポーチ・窓花箱
	var root := Node3D.new()
	root.name = "Cottage"

	var wall := VisualKit.plaster_material()
	var wood := VisualKit.bark_shader_material(Color(0.26, 0.16, 0.09))
	var roof := VisualKit.roof_tile_material()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.42, 0.40, 0.36)
	stone.roughness = 1.0
	stone.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	stone.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# 石積み：濃い不透明の丸石だけ。白い板は隠す
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(3.4, 0.22, 2.6)
	plinth.mesh = pm
	plinth.material_override = stone
	plinth.position = Vector3(0, 0.08, -0.1)
	root.add_child(plinth)
	# 前面の石：重なりすぎないよう1列＋少し互い違い
	for i in 10:
		var cob := MeshInstance3D.new()
		cob.mesh = CraftMeshes.uv_sphere(0.26 + fmod(float(i) * 0.02, 0.06), 10, 12, 0.06, float(i) * 4.7, 0.75)
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(0.38, 0.36, 0.32).lerp(Color(0.28, 0.30, 0.26), fmod(float(i) * 0.19, 1.0))
		cm.roughness = 1.0
		cm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		cob.material_override = cm
		cob.position = Vector3(-1.7 + float(i) * 0.38, 0.22 + (0.06 if i % 2 == 0 else 0.0), 1.52)
		cob.scale = Vector3(1.1, 0.95, 1.0)
		cob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(cob)
	for i in 5:
		for side in [-1.0, 1.0]:
			var cob := MeshInstance3D.new()
			cob.mesh = CraftMeshes.uv_sphere(0.24, 9, 11, 0.06, float(i) * 3.1 + side, 0.8)
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.36, 0.35, 0.31)
			cm.roughness = 1.0
			cm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			cob.material_override = cm
			cob.position = Vector3(side * 1.68, 0.2, -0.8 + float(i) * 0.5)
			cob.scale = Vector3(1.05, 0.9, 1.1)
			cob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(cob)

	# 漆喰本体（参照：横広・低め）
	var body := MeshInstance3D.new()
	var bodym := BoxMesh.new()
	bodym.size = Vector3(3.35, 1.75, 2.45)
	body.mesh = bodym
	body.material_override = wall
	body.position.y = 1.18
	root.add_child(body)

	# 前面の太いハーフティンバー
	_beam(root, wood, Vector3(-1.65, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(1.65, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(0, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(0, 0.42, 1.28), Vector3(3.35, 0.2, 0.16))
	_beam(root, wood, Vector3(0, 1.18, 1.28), Vector3(3.35, 0.18, 0.16))
	_beam(root, wood, Vector3(0, 1.95, 1.28), Vector3(3.35, 0.2, 0.16))
	var d1 := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.25, 0.16, 0.12)
	d1.mesh = dm
	d1.material_override = wood
	d1.position = Vector3(-0.82, 1.18, 1.32)
	d1.rotation_degrees.z = 28
	root.add_child(d1)
	var d2 := d1.duplicate() as MeshInstance3D
	d2.position = Vector3(0.82, 1.18, 1.32)
	d2.rotation_degrees.z = -28
	root.add_child(d2)

	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.70, 1.18, -1.1), Vector3(0.16, 1.75, 0.14))
		_beam(root, wood, Vector3(side * 1.70, 1.18, 1.1), Vector3(0.16, 1.75, 0.14))
		_beam(root, wood, Vector3(side * 1.70, 0.42, 0), Vector3(0.16, 0.16, 2.35))
		_beam(root, wood, Vector3(side * 1.70, 1.95, 0), Vector3(0.16, 0.16, 2.35))

	# 屋根下地＋瓦（参照：急勾配）
	var roof_base_l := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(4.1, 0.12, 2.05)
	roof_base_l.mesh = rbm
	roof_base_l.material_override = roof
	roof_base_l.position = Vector3(0, 2.35, -0.5)
	roof_base_l.rotation_degrees.x = -38
	root.add_child(roof_base_l)
	var roof_base_r := roof_base_l.duplicate() as MeshInstance3D
	roof_base_r.position = Vector3(0, 2.35, 0.5)
	roof_base_r.rotation_degrees.x = 38
	root.add_child(roof_base_r)
	_add_tiled_roof_side(root, roof, -1.0)
	_add_tiled_roof_side(root, roof, 1.0)
	_beam(root, wood, Vector3(0, 3.05, 0), Vector3(4.0, 0.18, 0.2))

	for side in [-1.0, 1.0]:
		# 妻壁は屋根に隠す（白い板を外に出さない）
		var gable := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.12, 0.85, 2.1)
		gable.mesh = gm
		gable.material_override = wall
		gable.position = Vector3(side * 1.62, 2.35, 0)
		root.add_child(gable)
		_beam(root, wood, Vector3(side * 1.68, 2.4, 0), Vector3(0.14, 1.0, 0.14))
		_beam(root, wood, Vector3(side * 1.68, 2.85, 0), Vector3(0.14, 0.14, 2.0))

	# ポーチ柱＋梁
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = CraftMeshes.trunk(1.15, 0.09, 0.07, 8)
		post.material_override = wood
		post.position = Vector3(side * 0.85, 0.42, 1.78)
		root.add_child(post)
	_beam(root, wood, Vector3(0, 1.5, 1.78), Vector3(1.85, 0.14, 0.16))

	# 凹み扉＋小窓
	_beam(root, wood, Vector3(0, 0.95, 1.28), Vector3(0.95, 1.25, 0.14))
	var door := MeshInstance3D.new()
	var doorm := BoxMesh.new()
	doorm.size = Vector3(0.78, 1.1, 0.06)
	door.mesh = doorm
	door.material_override = VisualKit.bark_shader_material(Color(0.28, 0.18, 0.1))
	door.position = Vector3(0, 0.95, 1.32)
	root.add_child(door)
	var dw := MeshInstance3D.new()
	var dwm := BoxMesh.new()
	dwm.size = Vector3(0.3, 0.3, 0.04)
	dw.mesh = dwm
	var dwmat := StandardMaterial3D.new()
	dwmat.albedo_color = Color(0.75, 0.88, 0.92)
	dwmat.emission_enabled = true
	dwmat.emission = Color(0.95, 0.85, 0.45)
	dwmat.emission_energy_multiplier = 1.2
	dw.material_override = dwmat
	dw.position = Vector3(0, 1.28, 1.38)
	root.add_child(dw)
	_beam(root, wood, Vector3(-0.18, 0.95, 1.36), Vector3(0.04, 1.0, 0.02))
	_beam(root, wood, Vector3(0.18, 0.95, 1.36), Vector3(0.04, 1.0, 0.02))
	var knob := MeshInstance3D.new()
	knob.mesh = CraftMeshes.uv_sphere(0.045, 5, 6)
	knob.material_override = VisualKit.character_material(Color(0.2, 0.18, 0.16), Color(0.1, 0.1, 0.1))
	knob.position = Vector3(0.26, 0.9, 1.38)
	root.add_child(knob)

	# 窓＋花箱（発光ガラスを前面に）
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.30), Vector3(0.78, 0.78, 0.12))
		var glass := MeshInstance3D.new()
		var glm := BoxMesh.new()
		glm.size = Vector3(0.56, 0.56, 0.05)
		glass.mesh = glm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(1.0, 0.9, 0.55)
		gmat.emission_enabled = true
		gmat.emission = Color(1.0, 0.85, 0.35)
		gmat.emission_energy_multiplier = 2.2
		gmat.roughness = 0.35
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass.material_override = gmat
		glass.position = Vector3(side * 1.1, 1.35, 1.40)
		root.add_child(glass)
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.43), Vector3(0.56, 0.05, 0.02))
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.43), Vector3(0.05, 0.56, 0.02))

	# 煙突（石の丸み）
	var chim := MeshInstance3D.new()
	chim.mesh = CraftMeshes.uv_sphere(0.32, 10, 12, 0.06, 3.3, 1.15)
	chim.material_override = stone
	chim.position = Vector3(-1.05, 2.85, -0.35)
	chim.scale = Vector3(1.0, 1.35, 1.0)
	root.add_child(chim)
	var chim_cap := MeshInstance3D.new()
	chim_cap.mesh = CraftMeshes.uv_sphere(0.28, 8, 10, 0.04, 4.1, 0.55)
	chim_cap.material_override = stone
	chim_cap.position = Vector3(-1.05, 3.35, -0.35)
	root.add_child(chim_cap)

	# 段
	_beam(root, wood, Vector3(0, 0.32, 1.75), Vector3(1.5, 0.18, 0.6))
	_beam(root, wood, Vector3(0, 0.18, 1.95), Vector3(1.2, 0.14, 0.45))

	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	for side in [-1.0, 1.0]:
		# 花箱は窓の下（窓ガラスと被せない）
		_beam(root, wood, Vector3(side * 1.1, 0.92, 1.48), Vector3(0.78, 0.18, 0.34))
		for j in 4:
			var f := flower(rng, ForestsPalette.petals()[j % 6])
			f.scale = Vector3.ONE * 0.5
			f.position = Vector3(side * 1.1 + (j - 1.5) * 0.13, 1.0, 1.58)
			root.add_child(f)

	return root


static func _add_tiled_roof_side(root: Node3D, roof_mat: Material, side_sign: float) -> void:
	## side_sign: -1 = 奥側, +1 = 手前側。厚みのある丸い瓦。
	var rows := 7
	var cols := 11
	for row in rows:
		var t := float(row) / float(rows - 1)
		var y := 2.2 + t * 0.78
		var z := side_sign * (1.05 - t * 0.95)
		for col in cols:
			var tile := MeshInstance3D.new()
			tile.mesh = CraftMeshes.uv_sphere(0.20, 7, 9, 0.04, float(col) * 1.7 + float(row), 0.55)
			tile.material_override = roof_mat
			var x := -1.85 + float(col) * 0.36 + (0.12 if row % 2 == 1 else 0.0)
			tile.position = Vector3(x, y + (col % 2) * 0.012, z)
			tile.scale = Vector3(1.15, 0.55, 1.05)
			tile.rotation_degrees.x = 38.0 * side_sign
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(tile)


static func _beam(root: Node3D, mat: Material, pos: Vector3, size: Vector3) -> void:
	var t := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	t.mesh = m
	t.material_override = mat
	t.position = pos
	root.add_child(t)
