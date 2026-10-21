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
# 参照樹：幹と趾は同じ中暗ニュートラル茶（二色割れ・オレンジ粘土禁止）
const BARK := Color(0.34, 0.24, 0.15)
const BARK_TOE := Color(0.34, 0.24, 0.15)
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
	var baked_h := 1.80
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
	# 趾は幹と同系の暖茶（参照全体樹で色が揃う）
	var bark_mat := VisualKit.bark_shader_material(BARK_TOE)
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
	var baked_h := 0.52
	var s := TOE_H / baked_h
	# 水平で aspect≈3、縦カプセル趾は残す
	toes.scale = Vector3(s * 2.05, s * 0.96, s * 2.05)
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
	# 結合時のみ：縦趾を立て、餅裾を抑える（部品Benchスケールは維持）
	var toe_mesh := toes.get_node_or_null("ToeSkirt") as Node3D
	if toe_mesh:
		toe_mesh.scale *= Vector3(0.66, 1.48, 0.66)
	root.add_child(toes)

	var trunk := trunk_fork_part()
	trunk.name = "TrunkFork"
	# 趾の立ち上がりを残しつつ水平割れを消す（食い込み過ぎで餅裾にしない）
	trunk.position.y = TOE_H * 0.50
	# 結合時のみ：幹を短く太く（部品Benchは維持）
	var trunk_mesh := trunk.get_node_or_null("TrunkFork") as Node3D
	if trunk_mesh:
		trunk_mesh.scale *= Vector3(1.12, 0.86, 1.12)
	root.add_child(trunk)

	# 参照全体樹の中幹横枝（部品Benchには出さない）
	var bark_mat := VisualKit.bark_shader_material(BARK)
	for side in [-1.0, 1.0]:
		var stub := MeshInstance3D.new()
		stub.mesh = CraftMeshes.trunk(0.26, 0.040, 0.022, 16)
		stub.material_override = bark_mat
		stub.position = Vector3(0.20 * side, trunk.position.y + TRUNK_H * 0.36, 0.02)
		stub.rotation_degrees.z = -82.0 * side
		stub.rotation_degrees.x = 6.0
		stub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(stub)

	var canopy := canopy_part()
	canopy.name = "Canopy"
	# 結合時のみ：参照全体樹のコンパクト中房へ（部品Benchは維持）
	var canopy_mesh := canopy.get_node_or_null("Canopy") as Node3D
	if canopy_mesh:
		canopy_mesh.scale *= Vector3(0.92, 1.12, 0.92)
	# 幹頂〜クレードルに冠を深く被せる（浮き冠禁止）
	canopy.position = Vector3(LEAN * 0.08, trunk.position.y + TRUNK_H * 0.68, 0.0)
	root.add_child(canopy)

	root.set_meta("tree_height", TRUNK_H)
	root.set_meta("hero", true)
	root.set_meta("assembled", true)
	return root
