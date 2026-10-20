extends RefCounted
class_name NatureFactory
## 参照シート準拠。闇雲に増やさず、目標形に合わせる。
## TREE: ref-tree-deciduous.jpg — 太い幹・根の指・短い枝・フェルト雲冠


## ヒーロー樹の固定比率（参照 ref-tree-deciduous.jpg）
## 幹高 : 樹冠幅 : 根幅  ≈  2.0 : 3.2 : 1.2  （幹は太く短め、冠は横広）
const HERO_TRUNK_H := 1.7
const HERO_BASE_R := 0.72
const HERO_TOP_R := 0.4
const HERO_CANOPY_R := 1.45
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

	var bark_tint := ForestsPalette.BARK_WARM.lerp(Color(0.48, 0.32, 0.2), 0.35 if hero else rng.randf() * 0.5)
	# セージ／オリーブ（参照：くすんだオリーブ。ミント／ライム禁止）
	var leaf := Color(0.36, 0.44, 0.30) if hero else Color(0.38, 0.46, 0.32).lerp(Color(0.34, 0.42, 0.28), rng.randf())
	var leaf_dark := Color(0.22, 0.30, 0.20)

	# 幹：参照どおり太く短め、根元フレア強め
	var trunk := MeshInstance3D.new()
	trunk.mesh = CraftMeshes.trunk(h * 0.92, base_r, top_r, 20 if hero else 16, lean, 0.035)
	trunk.material_override = VisualKit.bark_shader_material(bark_tint)
	root.add_child(trunk)

	# 根の指（参照の toe-like roots）— 正面から必ず見える大きさ
	var toes := 5 if not backdrop else 4
	for i in toes:
		var toe := MeshInstance3D.new()
		toe.mesh = CraftMeshes.uv_sphere(0.3 if hero else 0.2, 10 if hero else 7, 12 if hero else 9, 0.07, float(i) * 3.1, 0.6)
		toe.material_override = VisualKit.bark_shader_material(bark_tint.darkened(0.04))
		var a := float(i) / float(toes) * TAU + 0.35
		var reach := 0.55 if hero else 0.28
		toe.position = Vector3(cos(a) * reach, 0.07, sin(a) * reach * 0.85)
		toe.scale = Vector3(1.7, 0.45, 1.25)
		toe.rotation.y = a
		toe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(toe)

	# 短い支持スタブ（参照：樹冠すぐ下の左右短い枝）
	for b in 2:
		var br := MeshInstance3D.new()
		var blen := 0.42 if hero else rng.randf_range(0.35, 0.5)
		br.mesh = CraftMeshes.branch(blen, 0.14 if hero else 0.06, 0.08 if hero else 0.022, 10, 0.08)
		br.material_override = VisualKit.bark_shader_material(bark_tint)
		var ang := (0.0 if b == 0 else PI) + lean * 1.5
		var by := h * 0.95
		br.position = Vector3(cos(ang) * 0.22 + lean * 0.2, by, sin(ang) * 0.03)
		br.rotation = Vector3(0.55, ang, 0.0)
		root.add_child(br)

	# 雲冠：参照どおり重なりフェルト房。
	# （放射メタボールは凹み方向で原点スパイク＝破片の原因だった）
	var canopy_root := Node3D.new()
	canopy_root.position = Vector3(lean * 0.08, h * 1.05, 0.0)
	canopy_root.scale = Vector3(1.2, 0.78, 1.14)
	root.add_child(canopy_root)
	var felt := VisualKit.foliage_material(leaf, leaf_dark)
	for lobe in CraftMeshes.canopy_felt_lobes(rng, canopy_r):
		var mi := MeshInstance3D.new()
		mi.mesh = lobe["mesh"]
		mi.position = lobe["pos"]
		mi.scale = lobe["scale"]
		mi.material_override = felt
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		canopy_root.add_child(mi)

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
	var wood := VisualKit.bark_shader_material(Color(0.32, 0.2, 0.12))
	var roof := VisualKit.roof_tile_material()
	var stone := VisualKit.character_material(Color(0.5, 0.48, 0.44), Color(0.34, 0.34, 0.3))

	# 石積み基壇（参照の cobble base）
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(3.6, 0.42, 3.0)
	plinth.mesh = pm
	plinth.material_override = stone
	plinth.position.y = 0.21
	root.add_child(plinth)
	# 前面の石の凹凸
	for i in 5:
		var cob := MeshInstance3D.new()
		cob.mesh = CraftMeshes.uv_sphere(0.16 + fmod(float(i) * 0.07, 0.06), 6, 8, 0.2, float(i) * 5.0, 0.7)
		cob.material_override = VisualKit.character_material(
			Color(0.48, 0.46, 0.42).lerp(Color(0.4, 0.42, 0.38), fmod(float(i) * 0.3, 1.0)),
			Color(0.3, 0.3, 0.28)
		)
		cob.position = Vector3(-1.3 + float(i) * 0.65, 0.22, 1.48)
		cob.scale = Vector3(1.2, 0.7, 0.9)
		cob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(cob)

	# 漆喰本体
	var body := MeshInstance3D.new()
	var bodym := BoxMesh.new()
	bodym.size = Vector3(2.9, 1.9, 2.25)
	body.mesh = bodym
	body.material_override = wall
	body.position.y = 1.25
	root.add_child(body)

	# 前面の太いハーフティンバー（壁より少し前に出して食い込みを防ぐ）
	_beam(root, wood, Vector3(-1.42, 1.25, 1.18), Vector3(0.16, 1.9, 0.12))
	_beam(root, wood, Vector3(1.42, 1.25, 1.18), Vector3(0.16, 1.9, 0.12))
	_beam(root, wood, Vector3(0, 1.25, 1.18), Vector3(0.16, 1.9, 0.12))
	_beam(root, wood, Vector3(0, 0.4, 1.18), Vector3(2.9, 0.16, 0.12))
	_beam(root, wood, Vector3(0, 1.25, 1.18), Vector3(2.9, 0.14, 0.12))
	_beam(root, wood, Vector3(0, 2.1, 1.18), Vector3(2.9, 0.16, 0.12))
	var d1 := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.15, 0.12, 0.08)
	d1.mesh = dm
	d1.material_override = wood
	d1.position = Vector3(-0.7, 1.25, 1.2)
	d1.rotation_degrees.z = 28
	root.add_child(d1)
	var d2 := d1.duplicate() as MeshInstance3D
	d2.position = Vector3(0.7, 1.25, 1.2)
	d2.rotation_degrees.z = -28
	root.add_child(d2)

	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.48, 1.25, -1.05), Vector3(0.1, 1.9, 0.1))
		_beam(root, wood, Vector3(side * 1.48, 1.25, 1.05), Vector3(0.1, 1.9, 0.1))
		_beam(root, wood, Vector3(side * 1.48, 0.4, 0), Vector3(0.1, 0.12, 2.2))
		_beam(root, wood, Vector3(side * 1.48, 2.1, 0), Vector3(0.1, 0.12, 2.2))

	# 屋根下地＋瓦（下地がないと隙間が目立つ）
	var roof_base_l := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(3.7, 0.12, 1.75)
	roof_base_l.mesh = rbm
	roof_base_l.material_override = roof
	roof_base_l.position = Vector3(0, 2.42, -0.48)
	roof_base_l.rotation_degrees.x = -30
	root.add_child(roof_base_l)
	var roof_base_r := roof_base_l.duplicate() as MeshInstance3D
	roof_base_r.position = Vector3(0, 2.42, 0.48)
	roof_base_r.rotation_degrees.x = 30
	root.add_child(roof_base_r)
	_add_tiled_roof_side(root, roof, -1.0)
	_add_tiled_roof_side(root, roof, 1.0)
	_beam(root, wood, Vector3(0, 2.88, 0), Vector3(3.8, 0.14, 0.22))

	for side in [-1.0, 1.0]:
		var gable := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.12, 1.1, 2.4)
		gable.mesh = gm
		gable.material_override = wall
		gable.position = Vector3(side * 1.45, 2.2, 0)
		root.add_child(gable)

	# ポーチ柱＋梁
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = CraftMeshes.trunk(1.3, 0.08, 0.06, 8)
		post.material_override = wood
		post.position = Vector3(side * 0.72, 0.38, 1.58)
		root.add_child(post)
	_beam(root, wood, Vector3(0, 1.62, 1.58), Vector3(1.6, 0.12, 0.14))

	# 凹み扉＋小窓
	_beam(root, wood, Vector3(0, 1.0, 1.08), Vector3(0.88, 1.35, 0.12))
	var door := MeshInstance3D.new()
	var doorm := BoxMesh.new()
	doorm.size = Vector3(0.72, 1.2, 0.06)
	door.mesh = doorm
	door.material_override = VisualKit.bark_shader_material(Color(0.28, 0.18, 0.1))
	door.position = Vector3(0, 1.0, 1.12)
	root.add_child(door)
	# 扉の小窓
	var dw := MeshInstance3D.new()
	var dwm := BoxMesh.new()
	dwm.size = Vector3(0.28, 0.28, 0.04)
	dw.mesh = dwm
	var dwmat := StandardMaterial3D.new()
	dwmat.albedo_color = Color(0.75, 0.88, 0.92)
	dwmat.emission_enabled = true
	dwmat.emission = Color(0.95, 0.85, 0.45)
	dwmat.emission_energy_multiplier = 0.45
	dw.material_override = dwmat
	dw.position = Vector3(0, 1.35, 1.16)
	root.add_child(dw)
	_beam(root, wood, Vector3(-0.16, 1.0, 1.16), Vector3(0.04, 1.1, 0.02))
	_beam(root, wood, Vector3(0.16, 1.0, 1.16), Vector3(0.04, 1.1, 0.02))
	var knob := MeshInstance3D.new()
	knob.mesh = CraftMeshes.uv_sphere(0.04, 5, 6)
	knob.material_override = VisualKit.character_material(Color(0.78, 0.62, 0.32), Color(0.48, 0.36, 0.16))
	knob.position = Vector3(0.24, 0.95, 1.18)
	root.add_child(knob)

	# 窓＋花箱（参照どおり左右）
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 0.95, 1.4, 1.15), Vector3(0.62, 0.62, 0.1))
		var glass := MeshInstance3D.new()
		var glm := BoxMesh.new()
		glm.size = Vector3(0.46, 0.46, 0.04)
		glass.mesh = glm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.7, 0.85, 0.9)
		gmat.emission_enabled = true
		gmat.emission = Color(0.95, 0.82, 0.4)
		gmat.emission_energy_multiplier = 0.55
		gmat.roughness = 0.25
		glass.material_override = gmat
		glass.position = Vector3(side * 0.95, 1.4, 1.2)
		root.add_child(glass)
		_beam(root, wood, Vector3(side * 0.95, 1.4, 1.22), Vector3(0.46, 0.05, 0.02))
		_beam(root, wood, Vector3(side * 0.95, 1.4, 1.22), Vector3(0.05, 0.46, 0.02))

	# 煙突（石）
	_beam(root, stone, Vector3(-0.95, 2.85, -0.35), Vector3(0.42, 0.95, 0.42))
	_beam(root, stone, Vector3(-0.95, 3.35, -0.35), Vector3(0.5, 0.1, 0.5))

	# 丸みのある段
	_beam(root, wood, Vector3(0, 0.3, 1.55), Vector3(1.3, 0.16, 0.55))
	_beam(root, wood, Vector3(0, 0.16, 1.75), Vector3(1.05, 0.12, 0.4))

	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 0.95, 1.02, 1.24), Vector3(0.62, 0.16, 0.26))
		for j in 2:
			var f := flower(rng, ForestsPalette.petals()[j % 6])
			f.scale = Vector3.ONE * 0.5
			f.position = Vector3(side * 0.95 + (j - 0.5) * 0.14, 1.1, 1.24)
			root.add_child(f)

	return root


static func _add_tiled_roof_side(root: Node3D, roof_mat: Material, side_sign: float) -> void:
	## side_sign: -1 = 奥側, +1 = 手前側
	var rows := 6
	var cols := 10
	for row in rows:
		var t := float(row) / float(rows - 1)
		var y := 2.15 + t * 0.55
		var z := side_sign * (0.95 - t * 0.75)
		for col in cols:
			var tile := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.38, 0.07, 0.32)
			tile.mesh = tm
			tile.material_override = roof_mat
			var x := -1.7 + float(col) * 0.38 + (0.1 if row % 2 == 1 else 0.0)
			tile.position = Vector3(x, y + (col % 2) * 0.01, z)
			tile.rotation_degrees.x = 30.0 * side_sign
			root.add_child(tile)


static func _beam(root: Node3D, mat: Material, pos: Vector3, size: Vector3) -> void:
	var t := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	t.mesh = m
	t.material_override = mat
	t.position = pos
	root.add_child(t)
