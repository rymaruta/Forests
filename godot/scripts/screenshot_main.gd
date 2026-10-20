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
	await create_timer(1.5).timeout
	for i in 12:
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

	# 1) スポーン全景
	if pivot and pivot.has_method("snap_to_target"):
		pivot.distance = 7.5
		pivot.height = 3.2
		pivot.yaw = 0.35
		pivot.pitch = -0.35
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/70-checkpoint-spawn.png")
	print("SHOT_SAVED spawn")

	# 2) 小屋方向
	if pivot:
		pivot.yaw = 2.5
		pivot.pitch = -0.3
		pivot.distance = 8.0
		pivot.snap_to_target()
	if player:
		player.global_position = Vector3(-2.5, 0.5, 3.5)
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/71-checkpoint-cottage.png")
	print("SHOT_SAVED cottage")

	# 3) 池・木立
	if pivot:
		pivot.yaw = -0.6
		pivot.pitch = -0.32
		pivot.distance = 8.5
		pivot.snap_to_target()
	if player:
		player.global_position = Vector3(3.0, 0.5, 0.5)
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/72-checkpoint-trees.png")
	print("SHOT_SAVED trees")
	quit(0)
