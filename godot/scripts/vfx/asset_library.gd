extends RefCounted
class_name AssetLibrary
## Kenney Nature Kit (CC0) の読み込みキャッシュ

const ROOT := "res://assets/models/kenney/"

static var _cache: Dictionary = {}


static func scene(name: String) -> PackedScene:
	var path := ROOT + name + ".glb"
	if _cache.has(path):
		return _cache[path]
	var ps: PackedScene = load(path)
	_cache[path] = ps
	return ps


static func instance(name: String, scale: float = 1.0, yaw_deg: float = 0.0) -> Node3D:
	var ps := scene(name)
	if ps == null:
		push_warning("Missing asset: %s" % name)
		return Node3D.new()
	var node := ps.instantiate() as Node3D
	node.scale = Vector3.ONE * scale
	node.rotation_degrees.y = yaw_deg
	return node


static func trees_deciduous() -> Array:
	return ["tree_default", "tree_default_dark", "tree_detailed", "tree_oak", "tree_fat", "tree_tall", "tree_small"]


static func trees_pine() -> Array:
	return ["tree_pineTallA", "tree_pineTallA_detailed", "tree_pineRoundA", "tree_pineDefaultA"]


static func flowers() -> Array:
	return [
		"flower_yellowA", "flower_yellowB", "flower_yellowC",
		"flower_purpleA", "flower_purpleB", "flower_redA", "flower_redB",
	]


static func bushes() -> Array:
	return ["plant_bush", "plant_bushDetailed", "plant_bushLarge", "plant_bushSmall"]


static func rocks_small() -> Array:
	return ["rock_smallA", "rock_smallB", "rock_smallFlatA"]


static func rocks_large() -> Array:
	return ["rock_largeA", "rock_largeB"]


static func grass_clumps() -> Array:
	return ["grass", "grass_large", "grass_leafs", "grass_leafsLarge"]
