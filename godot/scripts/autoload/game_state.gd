extends Node
## セッション状態・所持・設定・選択中インタラクト

signal inventory_changed
signal selection_changed(target: Node3D)
signal toast_requested(message: String)
signal settings_changed

const ITEM_DEFS := {
	"softwood": {"name": "やわらかい木片", "color": Color(0.55, 0.38, 0.22)},
	"pine_needle": {"name": "青葉", "color": Color(0.35, 0.55, 0.32)},
	"river_pebble": {"name": "川石", "color": Color(0.55, 0.58, 0.62)},
	"sunpetal": {"name": "ひだまり花弁", "color": Color(0.92, 0.72, 0.35)},
	"moss_tuft": {"name": "こけ房", "color": Color(0.32, 0.52, 0.34)},
}

var inventory: Dictionary = {} # item_id -> count
var harvested_ids: Dictionary = {} # interactable_id -> true

var joystick_sensitivity: float = 1.0
var camera_sensitivity: float = 1.0
var master_volume: float = 0.8
var show_tutorial: bool = true
var player_name: String = "旅人"

var selected: Node3D = null
var is_menu_open: bool = false


func _ready() -> void:
	pass


func reset_session() -> void:
	inventory.clear()
	harvested_ids.clear()
	selected = null
	is_menu_open = false
	inventory_changed.emit()
	selection_changed.emit(null)


func add_item(item_id: String, amount: int = 1) -> void:
	if not ITEM_DEFS.has(item_id):
		push_warning("Unknown item: %s" % item_id)
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	inventory_changed.emit()
	var label: String = ITEM_DEFS[item_id]["name"]
	toast_requested.emit("%s ×%d を手に入れた" % [label, amount])


func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func total_items() -> int:
	var n := 0
	for k in inventory.keys():
		n += int(inventory[k])
	return n


func set_selected(target: Node3D) -> void:
	selected = target
	selection_changed.emit(target)


func mark_harvested(id: String) -> void:
	harvested_ids[id] = true


func is_harvested(id: String) -> bool:
	return harvested_ids.has(id)


func item_display_name(item_id: String) -> String:
	if ITEM_DEFS.has(item_id):
		return ITEM_DEFS[item_id]["name"]
	return item_id
