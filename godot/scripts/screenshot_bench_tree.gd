extends SceneTree
## 樹ヒーローだけBench撮影

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts/screenshots")
	var gs := root.get_node_or_null("/root/GameState")
	if gs:
		gs.show_tutorial = false
		gs.is_menu_open = false
	var packed: PackedScene = load("res://scenes/bench/AssetBench.tscn")
	var bench: Node3D = packed.instantiate()
	bench.name = "AssetBench"
	bench.set("subject", "tree")
	root.add_child(bench)
	await create_timer(0.8).timeout
	for i in 16:
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/bench-tree.png")
	print("BENCH_SAVED tree")
	quit(0)
