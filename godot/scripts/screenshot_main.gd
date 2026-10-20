extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gs := root.get_node_or_null("/root/GameState")
	if gs:
		gs.show_tutorial = false
		gs.is_menu_open = false
	var packed: PackedScene = load("res://scenes/world/Main.tscn")
	var main := packed.instantiate()
	root.add_child(main)
	await create_timer(1.2).timeout
	for i in 10:
		await process_frame
	var tut := main.get_node_or_null("HUD/Tutorial")
	if tut:
		tut.visible = false
	if gs:
		gs.is_menu_open = false
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "/opt/cursor/artifacts/screenshots/63-polish-spawn.png"
	img.save_png(path)
	print("SHOT_SAVED ", path, " size=", img.get_width(), "x", img.get_height())
	var pivot := main.get_node_or_null("CameraPivot")
	if pivot and pivot.has_method("snap_to_target"):
		pivot.yaw = 2.4
		pivot.pitch = -0.28
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	var path2 := "/opt/cursor/artifacts/screenshots/64-polish-cottage.png"
	img.save_png(path2)
	print("SHOT_SAVED ", path2)
	if pivot:
		pivot.yaw = -0.8
		pivot.snap_to_target()
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	var path3 := "/opt/cursor/artifacts/screenshots/65-polish-trees.png"
	img.save_png(path3)
	print("SHOT_SAVED ", path3)
	quit(0)
