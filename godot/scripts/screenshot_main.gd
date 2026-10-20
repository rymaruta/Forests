extends SceneTree
## 参照シートと並べて検証する撮影

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

	# 1) 樹のシルエット（参照ツリーと比較用）
	if player:
		player.global_position = Vector3(5.5, 0.5, 2.0)
		if player.has_method("set_facing_yaw"):
			player.set_facing_yaw(0.5)
	if pivot and pivot.has_method("snap_to_target"):
		pivot.distance = 5.5
		pivot.height = 2.4
		pivot.yaw = -0.4
		pivot.pitch = -0.15
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/90-vs-ref-tree.png")
	print("SHOT_SAVED tree")

	# 2) 小屋正面（参照コテージと比較）
	if player:
		player.global_position = Vector3(-3.0, 0.5, 3.5)
		if player.has_method("set_facing_yaw"):
			player.set_facing_yaw(-0.5)
	if pivot:
		pivot.yaw = 0.2
		pivot.pitch = -0.18
		pivot.distance = 6.5
		pivot.height = 2.5
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/91-vs-ref-cottage.png")
	print("SHOT_SAVED cottage")

	# 3) 旅人正面（参照キャラと比較）
	if player:
		player.global_position = Vector3(0.0, 0.5, 3.0)
		if player.has_method("set_facing_yaw"):
			player.set_facing_yaw(PI) # face camera-ish depending on orbit
	if pivot:
		pivot.yaw = 0.0
		pivot.pitch = -0.12
		pivot.distance = 3.8
		pivot.height = 1.8
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/92-vs-ref-traveler.png")
	print("SHOT_SAVED traveler")

	# 4) 場面全体
	if player:
		player.global_position = Vector3(0.0, 0.5, 3.0)
		if player.has_method("set_facing_yaw"):
			player.set_facing_yaw(0.3)
	if pivot:
		pivot.yaw = 0.45
		pivot.pitch = -0.3
		pivot.distance = 8.0
		pivot.height = 3.2
		pivot.snap_to_target()
	await process_frame
	await process_frame
	await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/screenshots/93-vs-ref-scene.png")
	print("SHOT_SAVED scene")
	quit(0)
