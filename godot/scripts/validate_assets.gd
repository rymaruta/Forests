extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_ps: PackedScene = load("res://scenes/world/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	await create_timer(0.8).timeout
	var gen := main.get_node_or_null("WorldBuilder/Generated")
	var count := 0
	if gen:
		count = gen.get_child_count()
	print("CRAFT_WORLD children=", count)
	quit(0 if count > 50 else 1)
