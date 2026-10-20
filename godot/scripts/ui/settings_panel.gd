extends Control
signal close_requested

var _player: Node3D


func _ready() -> void:
	visible = false
	$Panel/CloseButton.pressed.connect(_on_close)
	$Panel/JoySlider.value_changed.connect(_on_joy)
	$Panel/CamSlider.value_changed.connect(_on_cam)
	$Panel/VolSlider.value_changed.connect(_on_vol)
	$Panel/DeleteButton.pressed.connect(_on_delete)
	$Panel/TitleButton.pressed.connect(_on_title)


func open_panel(player: Node3D) -> void:
	_player = player
	visible = true
	$Panel/JoySlider.value = GameState.joystick_sensitivity
	$Panel/CamSlider.value = GameState.camera_sensitivity
	$Panel/VolSlider.value = GameState.master_volume


func _on_joy(v: float) -> void:
	GameState.joystick_sensitivity = v
	GameState.settings_changed.emit()


func _on_cam(v: float) -> void:
	GameState.camera_sensitivity = v
	GameState.settings_changed.emit()


func _on_vol(v: float) -> void:
	GameState.master_volume = v
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.001)))
	GameState.settings_changed.emit()


func _on_delete() -> void:
	SaveService.delete_save()
	GameState.toast_requested.emit("セーブデータを消した")


func _on_title() -> void:
	if _player:
		SaveService.save_game(_player)
	get_tree().change_scene_to_file("res://scenes/boot/Title.tscn")


func _on_close() -> void:
	if _player:
		SaveService.save_game(_player)
	close_requested.emit()
	visible = false
