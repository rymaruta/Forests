extends SceneTree
## AssetBench で参照と同じ条件の単体写真を撮る。
## 使い方: godot --path . --script res://scripts/screenshot_bench.gd

const OUT := "/opt/cursor/artifacts/screenshots"
const SUBJECTS := ["tree", "cottage", "traveler"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs := root.get_node_or_null("/root/GameState")
	if gs:
		gs.show_tutorial = false
		gs.is_menu_open = false

	for subj in SUBJECTS:
		await _shoot(subj)

	print("BENCH_SHOTS_DONE")
	quit(0)


func _shoot(subj: String) -> void:
	_clear_previous_bench()
	await process_frame

	var packed: PackedScene = load("res://scenes/bench/AssetBench.tscn")
	var bench: Node3D = packed.instantiate()
	bench.name = "AssetBench"
	bench.set("subject", subj)
	root.add_child(bench)

	await create_timer(0.7).timeout
	for i in 14:
		await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "%s/bench-%s.png" % [OUT, subj]
	img.save_png(path)
	print("BENCH_SAVED ", subj, " -> ", path)

	bench.queue_free()
	await process_frame


func _clear_previous_bench() -> void:
	for c in root.get_children():
		if String(c.name) == "AssetBench":
			c.free()
