extends Control
signal close_requested


func _ready() -> void:
	visible = false
	$Panel/CloseButton.pressed.connect(func(): close_requested.emit(); visible = false)
	GameState.inventory_changed.connect(_rebuild)


func open_panel() -> void:
	visible = true
	_rebuild()


func _rebuild() -> void:
	var list: VBoxContainer = $Panel/Scroll/List
	for c in list.get_children():
		c.queue_free()
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "まだ何も入っていない。\n森を歩いて採集してみよう。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)
		return
	for item_id in GameState.inventory.keys():
		var row := HBoxContainer.new()
		var name_l := Label.new()
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.text = GameState.item_display_name(str(item_id))
		var count_l := Label.new()
		count_l.text = "×%d" % int(GameState.inventory[item_id])
		row.add_child(name_l)
		row.add_child(count_l)
		list.add_child(row)
