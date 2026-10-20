extends Node3D
## メインプレイシーンの司令塔

@onready var world_builder: WorldBuilder = $WorldBuilder
@onready var player: PlayerController = $Player
@onready var camera_pivot: CameraOrbit = $CameraPivot
@onready var hud: CanvasLayer = $HUD
@onready var sun: DirectionalLight3D = $Sun

var _save_data: Dictionary = {}
var _toast_timer: float = 0.0


func _ready() -> void:
	camera_pivot.target_path = camera_pivot.get_path_to(player)

	if not GameState.toast_requested.is_connected(_on_toast):
		GameState.toast_requested.connect(_on_toast)
	if not GameState.selection_changed.is_connected(_on_selection):
		GameState.selection_changed.connect(_on_selection)
	if not GameState.inventory_changed.is_connected(_refresh_item_chip):
		GameState.inventory_changed.connect(_refresh_item_chip)

	_wire_hud()
	_refresh_item_chip()
	_update_action_button()

	# 生成中に床抜けしないよう物理を止める
	player.set_physics_process(false)
	player.visible = false
	GameState.toast_requested.emit("森を育てています…")
	await world_builder.build_async()
	_apply_loaded_save()
	if player.global_position.y < -1.0 or player.global_position.y > 8.0:
		player.global_position = Vector3(0.0, VisualKit._h(0.0, 3.0) + 0.35, 3.0)
	player.velocity = Vector3.ZERO
	player.visible = true
	player.set_physics_process(true)
	GameState.toast_requested.emit("森が息づいた")

	if GameState.show_tutorial:
		hud.get_node("Tutorial").visible = true
		GameState.is_menu_open = true


func _wire_hud() -> void:
	var joy: VirtualJoystick = hud.get_node("Root/Joystick")
	joy.move_vector_changed.connect(func(v: Vector2): player.set_move_input(v))

	hud.get_node("Root/ActionButton").pressed.connect(_on_action_pressed)
	hud.get_node("Root/BagButton").pressed.connect(_open_inventory)
	hud.get_node("Root/SettingsButton").pressed.connect(_open_settings)
	hud.get_node("Root/SaveButton").pressed.connect(_manual_save)

	hud.get_node("InventoryPanel").close_requested.connect(_close_menus)
	hud.get_node("SettingsPanel").close_requested.connect(_close_menus)
	hud.get_node("Tutorial").close_requested.connect(_close_tutorial)


func _apply_loaded_save() -> void:
	if SaveService.has_meta("pending_player_data"):
		_save_data = SaveService.get_meta("pending_player_data")
		SaveService.remove_meta("pending_player_data")
		SaveService.apply_player_transform(player, _save_data)
	elif SaveService.has_save() and GameState.inventory.is_empty() and GameState.harvested_ids.is_empty():
		# 直接 Main を開いた場合のフォールバック
		_save_data = SaveService.load_game()
		SaveService.apply_player_transform(player, _save_data)
	# 採取済み見た目は Interactable._ready で反映済み


func configure_continue(data: Dictionary) -> void:
	_save_data = data
	if is_node_ready():
		SaveService.apply_player_transform(player, data)


func _process(delta: float) -> void:
	# 穏やかな日照変化（簡易）
	sun.rotation_degrees.x = -42 + sin(Time.get_ticks_msec() * 0.00005) * 8.0

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			hud.get_node("Root/Toast").visible = false


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_menu_open:
		return
	if event is InputEventScreenTouch and event.pressed:
		_try_select_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 左半分ジョイスティック以外
		var vp := get_viewport().get_visible_rect().size
		if event.position.x > vp.x * 0.28:
			_try_select_at(event.position)


func _try_select_at(screen_pos: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 80.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4 # interactable
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		GameState.set_selected(null)
		return
	var collider: Node = hit["collider"]
	if collider is Interactable:
		var it := collider as Interactable
		# 近さチェック
		if player.global_position.distance_to(it.global_position) > 4.5:
			GameState.toast_requested.emit("もう少し近づこう")
			return
		_select(it)


func _select(it: Interactable) -> void:
	if GameState.selected and GameState.selected is Interactable:
		(GameState.selected as Interactable).set_highlighted(false)
	GameState.set_selected(it)
	it.set_highlighted(true)
	GameState.toast_requested.emit(it.examine())
	_update_action_button()


func _on_selection(_t: Node3D) -> void:
	_update_action_button()


func _update_action_button() -> void:
	var btn: Button = hud.get_node("Root/ActionButton")
	var it := GameState.selected as Interactable
	if it and it.can_harvest():
		btn.disabled = false
		btn.text = "採る"
	elif it:
		btn.disabled = true
		btn.text = "休中"
	else:
		btn.disabled = true
		btn.text = "行動"


func _on_action_pressed() -> void:
	var it := GameState.selected as Interactable
	if it == null:
		return
	if it.try_harvest():
		_spawn_pickup_fx(it.global_position + Vector3(0, 0.8, 0))
		_update_action_button()
		# オートセーブ（採取時）
		SaveService.save_game(player)


func _spawn_pickup_fx(pos: Vector3) -> void:
	var fx := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	fx.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.8, 0.3)
	mat.emission_energy_multiplier = 2.0
	fx.material_override = mat
	fx.global_position = pos
	add_child(fx)
	var tw := create_tween()
	tw.tween_property(fx, "position:y", pos.y + 1.2, 0.55)
	tw.parallel().tween_property(fx, "scale", Vector3.ZERO, 0.55)
	tw.tween_callback(fx.queue_free)


func _on_toast(message: String) -> void:
	var toast: Label = hud.get_node("Root/Toast")
	toast.text = message
	toast.visible = true
	_toast_timer = 2.6


func _refresh_item_chip() -> void:
	var chip: Label = hud.get_node("Root/ItemChip")
	chip.text = "かばん %d" % GameState.total_items()


func _open_inventory() -> void:
	GameState.is_menu_open = true
	hud.get_node("InventoryPanel").open_panel()
	player.set_move_input(Vector2.ZERO)


func _open_settings() -> void:
	GameState.is_menu_open = true
	hud.get_node("SettingsPanel").open_panel(player)
	player.set_move_input(Vector2.ZERO)


func _close_menus() -> void:
	hud.get_node("InventoryPanel").visible = false
	hud.get_node("SettingsPanel").visible = false
	if not hud.get_node("Tutorial").visible:
		GameState.is_menu_open = false


func _close_tutorial() -> void:
	hud.get_node("Tutorial").visible = false
	GameState.show_tutorial = false
	GameState.is_menu_open = false
	SaveService.save_game(player)


func _manual_save() -> void:
	if SaveService.save_game(player):
		GameState.toast_requested.emit("記録した")
	else:
		GameState.toast_requested.emit("記録に失敗")


func _notification(what: int) -> void:
	# アプリ一時停止時オートセーブ
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveService.save_game(player)
