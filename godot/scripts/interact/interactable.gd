extends StaticBody3D
class_name Interactable
## タップで調べ・採取できるオブジェクト

signal harvested(interactable: Interactable)

@export var interact_id: String = ""
@export var display_name: String = "対象"
@export var examine_text: String = "そっと触れてみる。"
@export var item_id: String = "softwood"
@export var item_amount: int = 1
@export var respawn_days: int = 0 ## MVPでは採取後は枯渇（0=再出現なし）

var _highlight: MeshInstance3D
var _depleted: bool = false


func _ready() -> void:
	collision_layer = 4 # interactable
	collision_mask = 0
	if interact_id == "":
		interact_id = "%s_%d_%d" % [name, int(global_position.x * 10), int(global_position.z * 10)]
	if GameState.is_harvested(interact_id):
		_apply_depleted(false)


func set_highlighted(on: bool) -> void:
	if _highlight == null:
		_ensure_highlight()
	_highlight.visible = on and not _depleted


func _ensure_highlight() -> void:
	_highlight = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.42
	_highlight.mesh = ring
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.95, 0.55, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.8, 0.3)
	mat.emission_energy_multiplier = 1.2
	_highlight.material_override = mat
	_highlight.position = Vector3(0, 0.05, 0)
	_highlight.visible = false
	add_child(_highlight)


func can_harvest() -> bool:
	return not _depleted


func examine() -> String:
	if _depleted:
		return "%sは今は休んでいる。" % display_name
	return examine_text


func try_harvest() -> bool:
	if _depleted:
		GameState.toast_requested.emit("もう採れない。また今度。")
		return false
	GameState.add_item(item_id, item_amount)
	GameState.mark_harvested(interact_id)
	_apply_depleted(true)
	harvested.emit(self)
	return true


func _apply_depleted(animate: bool) -> void:
	_depleted = true
	set_highlighted(false)
	# 見た目を少し沈ませる
	if animate:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(0.85, 0.55, 0.85), 0.35)
	else:
		scale = Vector3(0.85, 0.55, 0.85)
	modulate_visuals(Color(0.7, 0.7, 0.65))


func modulate_visuals(c: Color) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.material_override is StandardMaterial3D:
				(mi.material_override as StandardMaterial3D).albedo_color = c
