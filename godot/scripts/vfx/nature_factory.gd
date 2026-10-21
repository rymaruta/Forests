extends RefCounted
class_name NatureFactory
## 参照シート準拠。闇雲に増やさず、目標形に合わせる。
## TREE: ref-tree-deciduous.jpg — 太い幹・根の指・短い枝・フェルト雲冠


## ヒーロー樹の固定比率（参照 ref-tree-deciduous.jpg）
## 幹高 : 樹冠幅 : 根幅  ≈  2.0 : 3.2 : 1.2  （幹は太く短め、冠は横広）
const HERO_TRUNK_H := 1.40
## 幹本体はやや細め。フレア幅は趾ブーストに任せる（太杭＋フィン化を防ぐ）
const HERO_BASE_R := 0.28
const HERO_TOP_R := 0.10
const HERO_CANOPY_R := 1.10
const HERO_SEED := 2901


static func deciduous_tree_hero(rng: RandomNumberGenerator = null) -> Node3D:
	## Bench合格用。部品を理想形にしてから結合（TreeParts）。
	if rng != null:
		rng.seed = HERO_SEED
	return TreeParts.assemble_hero()


static func deciduous_part_canopy() -> Node3D:
	return TreeParts.canopy_part()


static func deciduous_part_trunk() -> Node3D:
	return TreeParts.trunk_fork_part()


static func deciduous_part_toes() -> Node3D:
	return TreeParts.toe_skirt_part()


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

	# 参照画素 mean: 幹≈(107,80,57) 冠≈(90,99,62)
	# 参照マスク mean: 幹≈(0.49,0.37,0.27) 冠≈(0.46,0.49,0.32)
	# 参照の暖かい中茶
	# 参照 bark mean ≈ (0.42, 0.32, 0.23)。縦繊維テクスチャが主で幾何溝は浅い
	# 参照幹 mean ≈ (0.42, 0.32, 0.23)
	var bark_tint := Color(0.44, 0.32, 0.22) if hero else ForestsPalette.BARK_WARM.lerp(Color(0.40, 0.26, 0.16), rng.randf() * 0.5)
	# 参照の暖かいセージ。暗すぎるフォレスト緑を避ける
	# 参照冠 mean ≈ (0.43, 0.46, 0.30)。微細パイルより房の陰影が主
	var leaf := Color(0.47, 0.52, 0.34) if hero else Color(0.4, 0.48, 0.35).lerp(Color(0.36, 0.44, 0.32), rng.randf())
	var leaf_dark := Color(0.30, 0.34, 0.20)

	# ヒーロー：一本メッシュ幹（連続フレア＋粘土趾丘）。MC soft-union は白欠けで捨てた。
	# ヒーローは幹を冠内まで伸ばして接合割れを隠す
	var trunk_h := h * (1.12 if hero else 0.92)
	var bark_mat := VisualKit.bark_shader_material(bark_tint)
	# 参照：5本前後の丸趾
	var toe_n := 5 if hero else (0 if backdrop else 4)
	var trunk := MeshInstance3D.new()
	trunk.name = "HeroTrunk" if hero else "Trunk"
	trunk.mesh = CraftMeshes.trunk(
		trunk_h,
		base_r,
		top_r,
		96 if hero else 16,
		lean,
		0.0 if hero else 0.028,
		true,
		toe_n
	)
	trunk.material_override = bark_mat
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(trunk)

	# 参照：幹頂の短い V フォーク。冠に食い込ませて黒い三角割れを隠す。
	# 別体趾は床フィン・貼り付け感で捨てた。趾は一本メッシュのみ。
	for b in 2:
		var br := MeshInstance3D.new()
		# 参照：短い V フォークが冠下から読める
		# 参照：短い U クレードル（鋭い V 禁止）
		var blen := 0.60 if hero else rng.randf_range(0.35, 0.5)
		br.mesh = CraftMeshes.branch(blen, 0.14 if hero else 0.06, 0.06 if hero else 0.022, 18, 0.10)
		br.material_override = VisualKit.bark_shader_material(bark_tint)
		var ang := (0.60 if b == 0 else PI - 0.60) + lean * 1.2
		var by := h * (0.82 if hero else (0.58 if b == 0 else 0.54))
		br.position = Vector3(cos(ang) * (base_r * 0.30 if hero else 0.2) + lean * 0.1, by, sin(ang) * (base_r * 0.12 if hero else 0.04))
		br.rotation = Vector3(0.70 if hero else 0.55, ang, 0.55 if (hero and b == 0) else (-0.55 if hero else 0.0))
		br.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(br)

	# 雲冠：ヒーローは事前生成の高解像ソフトユニオンOBJ
	var canopy := MeshInstance3D.new()
	if hero and ResourceLoader.exists("res://assets/meshes/canopy_hero.obj"):
		canopy.mesh = load("res://assets/meshes/canopy_hero.obj") as Mesh
	if canopy.mesh == null:
		canopy.mesh = CraftMeshes.canopy_soft_union(rng, canopy_r)
	canopy.material_override = VisualKit.foliage_material(leaf, leaf_dark)
	# 幹頂は冠に食い込み、短いクレードルは冠下に残す
	canopy.position = Vector3(lean * 0.08, h * 0.98, 0.0)
	if hero:
		# OBJ は BASE_R=1.30 で焼く。横を抑え縦を伸ばして参照の縦長雲へ
		var baked_r := 1.30
		var s := canopy_r / baked_r
		canopy.scale = Vector3(s * 0.92, s * 1.12, s * 0.92)
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)
	# 趾パッドと樹皮溝が正面で読めるヨー
	if hero:
		root.rotation.y = 0.72

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
	var wood := VisualKit.bark_shader_material(Color(0.20, 0.12, 0.07))
	var roof := VisualKit.roof_tile_material()
	var stone := VisualKit.cobble_material(Color(0.34, 0.34, 0.36))

	# 石積み：濃い不透明の丸石だけ。白い板は隠す（プラinthは石色で埋める）
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(3.35, 0.18, 2.55)
	plinth.mesh = pm
	plinth.material_override = stone
	plinth.position = Vector3(0, 0.06, -0.1)
	root.add_child(plinth)
	# 前面の石：潰した球ベース（直方の角を読ませない）
	for i in 16:
		var tint := Color(0.38, 0.38, 0.40).lerp(Color(0.24, 0.25, 0.26), fmod(float(i) * 0.17, 1.0))
		var cob := MeshInstance3D.new()
		cob.mesh = CraftMeshes.uv_sphere(0.16 + fmod(float(i) * 0.013, 0.05), 10, 12, 0.07, float(i) * 2.7, 0.88)
		cob.material_override = VisualKit.cobble_material(tint)
		cob.position = Vector3(-1.95 + float(i) * 0.26, 0.14, 1.54)
		cob.scale = Vector3(1.35 + fmod(float(i) * 0.09, 0.25), 0.62 + fmod(float(i) * 0.05, 0.18), 1.15)
		cob.rotation_degrees.y = fmod(float(i) * 19.0, 30.0) - 15.0
		cob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(cob)
	for i in 4:
		for side in [-1.0, 1.0]:
			var rad := 0.22
			var cob := MeshInstance3D.new()
			cob.mesh = CraftMeshes.uv_sphere(rad, 12, 14, 0.06, float(i) * 3.1 + side, 1.0)
			cob.material_override = VisualKit.cobble_material(Color(0.40, 0.40, 0.41))
			cob.position = Vector3(side * 1.72, rad + 0.01, -0.7 + float(i) * 0.55)
			cob.scale = Vector3(1.0, 1.12, 1.05)
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

	# 前面のハーフティンバー（参照に寄せてやや細く）
	_beam(root, wood, Vector3(-1.65, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(1.65, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(0, 1.18, 1.28), Vector3(0.22, 1.75, 0.16))
	_beam(root, wood, Vector3(0, 0.42, 1.28), Vector3(3.35, 0.18, 0.16))
	_beam(root, wood, Vector3(0, 1.18, 1.28), Vector3(3.35, 0.17, 0.16))
	_beam(root, wood, Vector3(0, 1.95, 1.28), Vector3(3.35, 0.18, 0.16))
	# 前面斜め梁：窓を避け上段ベイのみ（参照ハーフティンバー）
	var d1 := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.95, 0.14, 0.11)
	d1.mesh = dm
	d1.material_override = wood
	d1.position = Vector3(-0.78, 1.68, 1.36)
	d1.rotation_degrees.z = 34
	root.add_child(d1)
	var d2 := d1.duplicate() as MeshInstance3D
	d2.position = Vector3(0.78, 1.68, 1.36)
	d2.rotation_degrees.z = -34
	root.add_child(d2)
	var d3 := d1.duplicate() as MeshInstance3D
	d3.position = Vector3(-0.78, 1.78, 1.36)
	d3.rotation_degrees.z = -34
	root.add_child(d3)
	var d4 := d1.duplicate() as MeshInstance3D
	d4.position = Vector3(0.78, 1.78, 1.36)
	d4.rotation_degrees.z = 34
	root.add_child(d4)
	# 下段ベイの短い斜め（窓下）
	var d5 := d1.duplicate() as MeshInstance3D
	d5.position = Vector3(-0.78, 0.72, 1.36)
	d5.rotation_degrees.z = 28
	d5.scale = Vector3(0.75, 1.0, 1.0)
	root.add_child(d5)
	var d6 := d1.duplicate() as MeshInstance3D
	d6.position = Vector3(0.78, 0.72, 1.36)
	d6.rotation_degrees.z = -28
	d6.scale = Vector3(0.75, 1.0, 1.0)
	root.add_child(d6)

	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.70, 1.18, -1.1), Vector3(0.16, 1.75, 0.14))
		_beam(root, wood, Vector3(side * 1.70, 1.18, 1.1), Vector3(0.16, 1.75, 0.14))
		_beam(root, wood, Vector3(side * 1.70, 0.42, 0), Vector3(0.16, 0.16, 2.35))
		_beam(root, wood, Vector3(side * 1.70, 1.95, 0), Vector3(0.16, 0.16, 2.35))

	# 屋根：瓦のみ前面（下地板を出さない＝単色ブロック屋根禁止）
	_add_tiled_roof_side(root, roof, -1.0)
	_add_tiled_roof_side(root, roof, 1.0)
	_beam(root, wood, Vector3(0, 3.02, 0), Vector3(4.0, 0.16, 0.18))
	# 軒下の太い木口梁（参照の深い軒）
	_beam(root, wood, Vector3(0, 2.12, 1.22), Vector3(3.70, 0.14, 0.18))
	_beam(root, wood, Vector3(0, 2.12, -1.22), Vector3(3.70, 0.14, 0.18))
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.85, 2.12, 0), Vector3(0.14, 0.14, 2.55))

	for side in [-1.0, 1.0]:
		# 妻壁は屋根に完全に隠す（白柱が屋根から突き出すのを禁止）
		var gable := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.10, 0.70, 1.9)
		gable.mesh = gm
		gable.material_override = wall
		gable.position = Vector3(side * 1.55, 2.25, 0)
		root.add_child(gable)
		_beam(root, wood, Vector3(side * 1.58, 2.28, 0), Vector3(0.12, 0.75, 0.12))
		_beam(root, wood, Vector3(side * 1.58, 2.62, 0), Vector3(0.12, 0.12, 1.7))
		# 妻の斜め梁（参照ハーフティンバー）
		var gdiag := MeshInstance3D.new()
		var gdm := BoxMesh.new()
		gdm.size = Vector3(0.10, 0.12, 1.05)
		gdiag.mesh = gdm
		gdiag.material_override = wood
		gdiag.position = Vector3(side * 1.58, 2.40, 0.35)
		gdiag.rotation_degrees.x = 32.0
		root.add_child(gdiag)
		var gdiag2 := gdiag.duplicate() as MeshInstance3D
		gdiag2.position = Vector3(side * 1.58, 2.40, -0.35)
		gdiag2.rotation_degrees.x = -32.0
		root.add_child(gdiag2)

	# ポーチ柱＋梁（扉幅に寄せる）
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = CraftMeshes.trunk(1.15, 0.08, 0.065, 8)
		post.material_override = wood
		post.position = Vector3(side * 0.55, 0.42, 1.72)
		root.add_child(post)
	_beam(root, wood, Vector3(0, 1.5, 1.72), Vector3(1.25, 0.12, 0.14))
	# ポーチ梁の短い斜め支え（参照ブラケット）
	for side in [-1.0, 1.0]:
		var br := MeshInstance3D.new()
		var brm := BoxMesh.new()
		brm.size = Vector3(0.28, 0.10, 0.08)
		br.mesh = brm
		br.material_override = wood
		br.position = Vector3(side * 0.42, 1.38, 1.70)
		br.rotation_degrees.z = -38.0 * side
		root.add_child(br)

	# 凹み扉＋小窓
	_beam(root, wood, Vector3(0, 0.95, 1.28), Vector3(0.95, 1.25, 0.14))
	var door := MeshInstance3D.new()
	var doorm := BoxMesh.new()
	doorm.size = Vector3(0.78, 1.1, 0.06)
	door.mesh = doorm
	door.material_override = VisualKit.bark_shader_material(Color(0.28, 0.18, 0.1))
	door.position = Vector3(0, 0.95, 1.32)
	root.add_child(door)
	# 扉上の二枚小窓（参照）
	for side in [-1.0, 1.0]:
		var dw := MeshInstance3D.new()
		var dwm := BoxMesh.new()
		dwm.size = Vector3(0.18, 0.18, 0.04)
		dw.mesh = dwm
		var dwmat := StandardMaterial3D.new()
		dwmat.albedo_color = Color(0.85, 0.70, 0.35)
		dwmat.emission_enabled = true
		dwmat.emission = Color(0.95, 0.78, 0.40)
		dwmat.emission_energy_multiplier = 1.6
		dwmat.roughness = 0.65
		dw.material_override = dwmat
		dw.position = Vector3(side * 0.14, 1.28, 1.38)
		root.add_child(dw)
	_beam(root, wood, Vector3(-0.18, 0.95, 1.36), Vector3(0.04, 1.0, 0.02))
	_beam(root, wood, Vector3(0.18, 0.95, 1.36), Vector3(0.04, 1.0, 0.02))
	_beam(root, wood, Vector3(0.0, 1.28, 1.39), Vector3(0.03, 0.18, 0.02))
	var knob := MeshInstance3D.new()
	knob.mesh = CraftMeshes.uv_sphere(0.040, 5, 6)
	knob.material_override = VisualKit.character_material(Color(0.22, 0.18, 0.14), Color(0.1, 0.08, 0.06))
	knob.position = Vector3(0.26, 0.88, 1.38)
	root.add_child(knob)

	# 窓＋花箱（発光ガラスを前面に）
	for side in [-1.0, 1.0]:
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.30), Vector3(0.78, 0.78, 0.12))
		var glass := MeshInstance3D.new()
		var glm := BoxMesh.new()
		glm.size = Vector3(0.56, 0.56, 0.05)
		glass.mesh = glm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.92, 0.68, 0.30)
		gmat.emission_enabled = true
		gmat.emission = Color(0.95, 0.70, 0.28)
		gmat.emission_energy_multiplier = 2.4
		gmat.roughness = 0.70
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		glass.material_override = gmat
		glass.position = Vector3(side * 1.1, 1.35, 1.40)
		root.add_child(glass)
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.43), Vector3(0.56, 0.05, 0.02))
		_beam(root, wood, Vector3(side * 1.1, 1.35, 1.43), Vector3(0.05, 0.56, 0.02))

	# 煙突：直方石ブロック積み（球禁止）
	var chim := MeshInstance3D.new()
	var chim_m := BoxMesh.new()
	chim_m.size = Vector3(0.48, 0.95, 0.48)
	chim.mesh = chim_m
	chim.material_override = VisualKit.cobble_material(Color(0.34, 0.34, 0.36))
	chim.position = Vector3(-1.05, 3.10, 0.15)
	root.add_child(chim)
	for ci in 3:
		var course := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.50 + fmod(float(ci) * 0.03, 0.04), 0.22, 0.50)
		course.mesh = cm
		course.material_override = VisualKit.cobble_material(
			Color(0.32, 0.32, 0.34).lerp(Color(0.38, 0.37, 0.36), fmod(float(ci) * 0.37, 1.0))
		)
		course.position = Vector3(-1.05, 2.78 + float(ci) * 0.22, 0.15)
		course.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(course)
	var chim_cap := MeshInstance3D.new()
	var cap_m := BoxMesh.new()
	cap_m.size = Vector3(0.58, 0.10, 0.58)
	chim_cap.mesh = cap_m
	chim_cap.material_override = VisualKit.cobble_material(Color(0.28, 0.28, 0.30))
	chim_cap.position = Vector3(-1.05, 3.62, 0.15)
	root.add_child(chim_cap)

	# 段（参照のポーチ段：扉幅に寄せる）
	_beam(root, wood, Vector3(0, 0.34, 1.72), Vector3(1.05, 0.14, 0.48))
	_beam(root, wood, Vector3(0, 0.20, 1.90), Vector3(0.95, 0.12, 0.42))
	_beam(root, wood, Vector3(0, 0.08, 2.05), Vector3(0.85, 0.10, 0.34))

	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	for side in [-1.0, 1.0]:
		# 花箱は窓の下（窓ガラスと被せない）
		_beam(root, wood, Vector3(side * 1.1, 0.92, 1.48), Vector3(0.78, 0.18, 0.34))
		for j in 7:
			var f := flower(rng, ForestsPalette.petals()[j % 6])
			f.scale = Vector3.ONE * (0.42 + fmod(float(j) * 0.11, 0.14))
			f.position = Vector3(side * 1.1 + (j - 3.0) * 0.09, 0.98 + fmod(float(j) * 0.07, 0.08), 1.56 + fmod(float(j) * 0.05, 0.06))
			root.add_child(f)

	return root


static func _add_tiled_roof_side(root: Node3D, roof_mat: Material, side_sign: float) -> void:
	## side_sign: -1 = 奥側, +1 = 手前側。細かい半円瓦の段を読ませる。
	var rows := 10
	var cols := 14
	for row in rows:
		var t := float(row) / float(rows - 1)
		var y := 2.16 + t * 0.88
		var z := side_sign * (1.12 - t * 1.05)
		for col in cols:
			var tile := MeshInstance3D.new()
			# 小さめの横長半潰し球＝瓦のうろこ
			tile.mesh = CraftMeshes.uv_sphere(0.20, 8, 10, 0.05, float(col) * 1.7 + float(row), 0.42)
			var shade := 0.72 + 0.34 * fmod(float(col * 2 + row * 3), 9.0) / 9.0
			var tm := roof_mat.duplicate() as ShaderMaterial
			if tm:
				var bc = tm.get_shader_parameter("base_color")
				if typeof(bc) == TYPE_COLOR:
					tm.set_shader_parameter("base_color", Color(bc.r * shade, bc.g * shade, bc.b * shade))
				elif typeof(bc) == TYPE_VECTOR3:
					tm.set_shader_parameter("base_color", bc * shade)
				tile.material_override = tm
			else:
				tile.material_override = roof_mat
			var x := -1.90 + float(col) * 0.29 + (0.14 if row % 2 == 1 else 0.0)
			tile.position = Vector3(x, y + 0.05, z + side_sign * 0.06)
			tile.scale = Vector3(1.40, 0.72, 1.25)
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
