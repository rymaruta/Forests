extends RefCounted
class_name TreeParts
## ヒーロー樹を部品に分けて理想形を作り、あとで結合する。
## 部品: canopy / trunk_fork / toe_skirt
## 各部品は単独Benchで参照パーツ写真に合わせる。混ぜて直さない。


const SEED := 2901
const TRUNK_H := 1.40
const BASE_R := 0.26
const TOP_R := 0.10
const CANOPY_R := 1.10
const TOE_H := 0.42
const TOE_BOTTOM_R := 0.34
const LEAN := 0.02
const BARK := Color(0.44, 0.32, 0.22)
# 参照冠の落ち着いたオリーブ（ライム黄み禁止）
const LEAF := Color(0.56, 0.60, 0.42)
const LEAF_DARK := Color(0.32, 0.38, 0.26)


static func canopy_part() -> Node3D:
	## 部品1: フェルト雲冠だけ。床は触らない。
	var root := Node3D.new()
	root.name = "PartCanopy"
	var canopy := MeshInstance3D.new()
	canopy.name = "Canopy"
	if ResourceLoader.exists("res://assets/meshes/canopy_hero.obj"):
		canopy.mesh = load("res://assets/meshes/canopy_hero.obj") as Mesh
	if canopy.mesh == null:
		var rng := RandomNumberGenerator.new()
		rng.seed = SEED
		canopy.mesh = CraftMeshes.canopy_soft_union(rng, CANOPY_R)
	canopy.material_override = VisualKit.foliage_material(LEAF, LEAF_DARK)
	var baked_r := 1.30
	var s := CANOPY_R / baked_r
	# 参照冠：やや横に重い丸雲。平らな横キノコ禁止
	canopy.scale = Vector3(s * 1.08, s, s * 1.08)
	canopy.position = Vector3(0.0, 0.0, 0.0)
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)
	# ディザ縁殻は参照と乖離するので付けない。毛羽は本体シェーダのみ。
	root.set_meta("part", "canopy")
	root.set_meta("part_height", CANOPY_R * 1.35)
	return root


static func trunk_fork_part() -> Node3D:
	## 部品2: 滑らかな幹柱＋短い U クレードル枝。趾なし。
	var root := Node3D.new()
	root.name = "PartTrunkFork"
	var bark_mat := VisualKit.bark_shader_material(BARK)

	var col := MeshInstance3D.new()
	col.name = "TrunkColumn"
	# 趾なし・浅いフレアのみ。幾何フルート禁止。
	col.mesh = CraftMeshes.trunk(
		TRUNK_H,
		BASE_R,
		TOP_R,
		96,
		LEAN,
		0.0,
		true,
		0
	)
	col.material_override = bark_mat
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(col)

	for b in 2:
		var br := MeshInstance3D.new()
		br.name = "Cradle_%d" % b
		var blen := 0.56
		br.mesh = CraftMeshes.branch(blen, 0.13, 0.055, 18, 0.10)
		br.material_override = bark_mat
		var ang := (0.55 if b == 0 else PI - 0.55) + LEAN * 1.2
		var by := TRUNK_H * 0.78
		br.position = Vector3(
			cos(ang) * (BASE_R * 0.22) + LEAN * 0.1,
			by,
			sin(ang) * (BASE_R * 0.08)
		)
		br.rotation = Vector3(0.58, ang, 0.48 if b == 0 else -0.48)
		br.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(br)

	root.rotation.y = 0.72
	root.set_meta("part", "trunk_fork")
	root.set_meta("part_height", TRUNK_H)
	return root


static func toe_skirt_part() -> Node3D:
	## 部品3: 粘土趾＋裾だけ。短い丘メッシュ。
	var root := Node3D.new()
	root.name = "PartToeSkirt"
	var bark_mat := VisualKit.bark_shader_material(BARK)
	var toes := MeshInstance3D.new()
	toes.name = "ToeSkirt"
	# 短い高さで趾を最大化。上端半径は幹柱 BASE_R に合わせる。
	toes.mesh = CraftMeshes.trunk(
		TOE_H,
		TOE_BOTTOM_R,
		BASE_R,
		96,
		0.0,
		0.0,
		true,
		5
	)
	toes.material_override = bark_mat
	toes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(toes)
	root.rotation.y = 0.72
	root.set_meta("part", "toe_skirt")
	root.set_meta("part_height", TOE_H)
	return root


static func assemble_hero() -> Node3D:
	## 合格部品をソケットで結合。結合後に比率だけ微調整。
	var root := Node3D.new()
	root.name = "HeroTreeAssembled"

	var toes := toe_skirt_part()
	toes.name = "ToeSkirt"
	root.add_child(toes)

	var trunk := trunk_fork_part()
	trunk.name = "TrunkFork"
	# 趾上面に食い込ませて水平割れを消す
	trunk.position.y = TOE_H * 0.55
	root.add_child(trunk)

	var canopy := canopy_part()
	canopy.name = "Canopy"
	# 幹頂〜クレードルの上に冠を被せる
	canopy.position = Vector3(LEAN * 0.08, trunk.position.y + TRUNK_H * 0.86, 0.0)
	root.add_child(canopy)

	root.set_meta("tree_height", TRUNK_H)
	root.set_meta("hero", true)
	root.set_meta("assembled", true)
	return root
