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
	await create_timer(1.8).timeout
	for i in 16:
		await process_frame
	var tut := main.get_node_or_null("HUD/Tutorial")
	if tut:
		tut.visible = false
	if gs:
		gs.is_menu_open = false
	var toast := main.get_node_or_null("HUD/Root/Toast")
	if toast:
		toast.visible = false

	var pivot := main.get_node_or_null("CameraPivot")
	var player := main.get_node_or_null("Player")
	if player:
		player.global_position = Vector3(0.0, 0.5, 3.0)

	# 1) spawn
	if pivot and pivot.has_method("snap_to_target"):
		pivot.distance = 7.2
		pivot.height = 3.0
		pivot.yaw = 0.4
		pivot.pitch = -0.32
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/80-overhaul-spawn.png")
	print("SHOT_SAVED spawn")

	# 2) cottage front (door / windows facing camera)
	if pivot:
		pivot.yaw = 0.15
		pivot.pitch = -0.2
		pivot.distance = 6.2
		pivot.height = 2.4
		pivot.snap_to_target()
	if player:
		player.global_position = Vector3(-3.2, 0.5, 3.2)
		if player.has_method("set_facing_yaw"):
			player.set_facing_yaw(-0.6)
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/81-overhaul-cottage.png")
	print("SHOT_SAVED cottage")

	# 3) pond / trees
	if pivot:
		pivot.yaw = -0.55
		pivot.pitch = -0.3
		pivot.distance = 8.2
		pivot.snap_to_target()
	if player:
		player.global_position = Vector3(3.2, 0.5, 0.2)
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/82-overhaul-trees.png")
	print("SHOT_SAVED trees")

	# 4) close tree detail
	if pivot:
		pivot.yaw = 0.2
		pivot.pitch = -0.2
		pivot.distance = 4.5
		pivot.height = 2.2
		pivot.snap_to_target()
	if player:
		player.global_position = Vector3(1.5, 0.5, -2.0)
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/83-overhaul-detail.png")
	print("SHOT_SAVED detail")
	quit(0)
