extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/world/Main.tscn")
	var main := packed.instantiate()
	root.add_child(main)
	# wait for build + a few frames
	await create_timer(1.5).timeout
	for i in 8:
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "/opt/cursor/artifacts/screenshots/61-local-main-spawn.png"
	img.save_png(path)
	print("SHOT_SAVED ", path, " size=", img.get_width(), "x", img.get_height())
	# rotate camera-ish by moving player view: find CameraOrbit
	var pivot := main.get_node_or_null("CameraPivot")
	if pivot and pivot.has_method("snap_to_target"):
		pivot.yaw = 2.2
		pivot.snap_to_target()
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	var path2 := "/opt/cursor/artifacts/screenshots/62-local-main-angle.png"
	img.save_png(path2)
	print("SHOT_SAVED ", path2)
	quit(0)
