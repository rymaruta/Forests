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
const BARK := Color(0.37, 0.29, 0.21)
# 参照冠の深いモスオリーブ（rb/g≈0.22）
const LEAF := Color(0.49, 0.50, 0.33)
const LEAF_DARK := Color(0.25, 0.27, 0.17)


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
	var baked_r := 1.28
	var s := CANOPY_R / baked_r
	# 参照冠：中房積雲 aspect≈1.4
	canopy.scale = Vector3(s * 1.175, s * 0.955, s * 1.175)
	canopy.position = Vector3(0.0, 0.0, 0.0)
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(canopy)
	# 半透明殻は白縁ハローになるので付けない。柔縁は本体シェーダのみ。
	root.set_meta("part", "canopy")
	root.set_meta("part_height", CANOPY_R * 1.35)
	return root


static func trunk_fork_part() -> Node3D:
	## 部品2: 滑らかな幹柱＋短い U クレードル枝。趾なし。
	var root := Node3D.new()
	root.name = "PartTrunkFork"
	var bark_mat := VisualKit.bark_shader_material(BARK)

	var col := MeshInstance3D.new()
	col.name = "TrunkFork"
	if ResourceLoader.exists("res://assets/meshes/trunk_fork.obj"):
		col.mesh = load("res://assets/meshes/trunk_fork.obj") as Mesh
	if col.mesh == null:
		# フォールバック：旧円錐＋枝（ベイク前）
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
	# ベイク高さ≈1.65 → TRUNK_H
	var baked_h := 1.73
	var s := TRUNK_H / baked_h
	col.scale = Vector3(s * 1.12, s, s * 1.12)
	root.add_child(col)

	# 参照パーツと同じくクレードル正面
	root.rotation.y = 0.0
	root.set_meta("part", "trunk_fork")
	root.set_meta("part_height", TRUNK_H)
	return root


static func toe_skirt_part() -> Node3D:
	## 部品3: 粘土趾＋裾だけ。短い丘メッシュ。
	var root := Node3D.new()
	root.name = "PartToeSkirt"
	# 趾は幹より一段暗い暖茶（参照 mean≈118/91/68）
	var bark_mat := VisualKit.bark_shader_material(Color(0.20, 0.14, 0.10))
	var toes := MeshInstance3D.new()
	toes.name = "ToeSkirt"
	if ResourceLoader.exists("res://assets/meshes/toe_skirt.obj"):
		toes.mesh = load("res://assets/meshes/toe_skirt.obj") as Mesh
	if toes.mesh == null:
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
	var baked_h := 0.41
	var s := TOE_H / baked_h
	# ベイクが低いと s が増えるので Y を抑えて aspect≈3
	toes.scale = Vector3(s * 2.10, s * 0.50, s * 2.10)
	root.add_child(toes)
	root.rotation.y = 0.0
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
