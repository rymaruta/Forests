extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var names := ["tree_oak", "tree_detailed", "flower_yellowA", "grass_large", "rock_largeA"]
	var ok := 0
	for n in names:
		var ps: PackedScene = load("res://assets/models/kenney/%s.glb" % n)
		if ps == null:
			print("MISSING ", n)
			continue
		var node := ps.instantiate()
		var meshes := _count_meshes(node)
		print("OK ", n, " meshes=", meshes)
		if meshes > 0:
			ok += 1
		node.free()
	print("ASSET_CHECK ok=", ok, "/", names.size())
	quit(0 if ok == names.size() else 1)

func _count_meshes(n: Node) -> int:
	var c := 0
	if n is MeshInstance3D:
		c += 1
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
