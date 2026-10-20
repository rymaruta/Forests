extends Control


func _ready() -> void:
	$Center/VBox/ContinueButton.disabled = not SaveService.has_save()
	$Center/VBox/NewButton.pressed.connect(_on_new)
	$Center/VBox/ContinueButton.pressed.connect(_on_continue)
	# 背景の簡易アニメ
	var tw := create_tween().set_loops()
	tw.tween_property($Backdrop, "modulate", Color(0.92, 1.0, 0.95), 3.0)
	tw.tween_property($Backdrop, "modulate", Color(1, 1, 1), 3.0)


func _on_new() -> void:
	GameState.reset_session()
	GameState.show_tutorial = true
	get_tree().change_scene_to_file("res://scenes/world/Main.tscn")


func _on_continue() -> void:
	var data := SaveService.load_game()
	get_tree().change_scene_to_file("res://scenes/world/Main.tscn")
	# Main の _ready で load 済みデータを位置に適用するため、
	# インベントリは既に GameState に入っている。位置は Main が再ロードする。
	# 二重ロードを避けるため、Main は has_save なら load する。
	# continue 時は既にロード済みなので Main 側で inventory 非空なら位置だけ適用するよう調整が必要。
	# → SaveService に last_loaded を保持する。
	SaveService.set_meta("pending_player_data", data)
