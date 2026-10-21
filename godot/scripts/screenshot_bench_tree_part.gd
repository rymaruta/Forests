extends SceneTree
## 樹部品Bench撮影。使い方: godot --script ... tree_canopy|tree_trunk|tree_toes


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts/screenshots")
	var part := "tree_canopy"
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and str(args[0]).begins_with("tree_"):
		part = str(args[0])
	elif args.size() >= 1 and str(args[0]) in ["canopy", "trunk", "toes"]:
		part = "tree_%s" % str(args[0])

	var gs := root.get_node_or_null("/root/GameState")
	if gs:
		gs.show_tutorial = false
		gs.is_menu_open = false
	var packed: PackedScene = load("res://scenes/bench/AssetBench.tscn")
	var bench: Node3D = packed.instantiate()
	bench.name = "AssetBench"
	bench.set("subject", part)
	root.add_child(bench)
	await create_timer(1.2).timeout
	for i in 24:
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	# 冠は参照写真の柔縁に寄せて 2x 縮小（撮影解像度が十分あるとき）
	if part == "tree_canopy" and img.get_width() >= 1920:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	var short := part.replace("tree_", "")
	var path := "/opt/cursor/artifacts/screenshots/bench-part-%s.png" % short
	img.save_png(path)
	print("BENCH_SAVED ", part, " -> ", path)
	quit(0)
