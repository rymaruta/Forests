extends Node
## user://save.json へのセーブ / ロード

const SAVE_PATH := "user://forests_save.json"
const SAVE_BACKUP := "user://forests_save.bak.json"

signal save_completed(ok: bool)
signal load_completed(ok: bool)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(player: Node3D = null) -> bool:
	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"player_name": GameState.player_name,
		"inventory": GameState.inventory.duplicate(true),
		"harvested_ids": GameState.harvested_ids.duplicate(true),
		"settings": {
			"joystick_sensitivity": GameState.joystick_sensitivity,
			"camera_sensitivity": GameState.camera_sensitivity,
			"master_volume": GameState.master_volume,
			"show_tutorial": GameState.show_tutorial,
		},
		"player": {
			"position": [0.0, 0.0, 0.0],
			"yaw": 0.0,
		},
	}

	if player and is_instance_valid(player):
		var p: Vector3 = player.global_position
		data["player"]["position"] = [p.x, p.y, p.z]
		if player.has_method("get_facing_yaw"):
			data["player"]["yaw"] = player.get_facing_yaw()
		elif "yaw" in player:
			data["player"]["yaw"] = player.yaw

	# backup previous
	if FileAccess.file_exists(SAVE_PATH):
		var prev := FileAccess.get_file_as_string(SAVE_PATH)
		var bak := FileAccess.open(SAVE_BACKUP, FileAccess.WRITE)
		if bak:
			bak.store_string(prev)
			bak.close()

	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		save_completed.emit(false)
		return false
	f.store_string(json)
	f.close()
	save_completed.emit(true)
	return true


func load_game() -> Dictionary:
	if not has_save():
		load_completed.emit(false)
		return {}

	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		# try backup
		if FileAccess.file_exists(SAVE_BACKUP):
			text = FileAccess.get_file_as_string(SAVE_BACKUP)
			parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			load_completed.emit(false)
			return {}

	var data: Dictionary = parsed
	GameState.player_name = str(data.get("player_name", "旅人"))
	GameState.inventory = data.get("inventory", {}).duplicate(true)
	GameState.harvested_ids = data.get("harvested_ids", {}).duplicate(true)

	var settings: Dictionary = data.get("settings", {})
	GameState.joystick_sensitivity = float(settings.get("joystick_sensitivity", 1.0))
	GameState.camera_sensitivity = float(settings.get("camera_sensitivity", 1.0))
	GameState.master_volume = float(settings.get("master_volume", 0.8))
	GameState.show_tutorial = bool(settings.get("show_tutorial", true))
	AudioServer.set_bus_volume_db(0, linear_to_db(GameState.master_volume))

	GameState.inventory_changed.emit()
	GameState.settings_changed.emit()
	load_completed.emit(true)
	return data


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(SAVE_BACKUP):
		DirAccess.remove_absolute(SAVE_BACKUP)
	GameState.reset_session()


func apply_player_transform(player: Node3D, data: Dictionary) -> void:
	if data.is_empty() or not data.has("player"):
		return
	var pdata: Dictionary = data["player"]
	var pos: Array = pdata.get("position", [0, 0, 0])
	if pos.size() >= 3:
		player.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	if player.has_method("set_facing_yaw"):
		player.set_facing_yaw(float(pdata.get("yaw", 0.0)))
