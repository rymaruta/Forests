extends Node3D
class_name CameraOrbit
## プレイヤー追従 + 右画面スワイプでオービット

@export var distance: float = 6.2
@export var height: float = 2.4
@export var min_pitch: float = -0.45
@export var max_pitch: float = 0.2

var target: Node3D = null
var yaw: float = 0.55
var pitch: float = -0.22
var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.current = true


func snap_to_target() -> void:
	if target == null:
		return
	global_position = target.global_position + Vector3(0, 1.0, 0)
	var offset := Vector3(
		sin(yaw) * cos(pitch) * distance,
		height + sin(-pitch) * distance * 0.35,
		cos(yaw) * cos(pitch) * distance
	)
	camera.position = offset
	camera.look_at(global_position + Vector3(0, 0.6, 0), Vector3.UP)


func _process(delta: float) -> void:
	if target == null or camera == null:
		return
	var desired := target.global_position + Vector3(0, 1.0, 0)
	global_position = global_position.lerp(desired, 1.0 - exp(-8.0 * delta))

	var offset := Vector3(
		sin(yaw) * cos(pitch) * distance,
		height + sin(-pitch) * distance * 0.35,
		cos(yaw) * cos(pitch) * distance
	)
	# ローカルオフセットを直接セット（lerpで発散しない）
	camera.position = offset
	var look := global_position + Vector3(0, 0.5, 0)
	if camera.global_position.distance_to(look) > 0.05:
		camera.look_at(look, Vector3.UP)


func _input(event: InputEvent) -> void:
	if GameState.is_menu_open:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var vp := get_viewport().get_visible_rect().size
		if st.pressed and st.position.x > vp.x * 0.42:
			_dragging = true
			_touch_index = st.index
			_last_pos = st.position
		elif not st.pressed and st.index == _touch_index:
			_dragging = false
			_touch_index = -1

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _dragging or sd.index != _touch_index:
			return
		_apply_look(sd.relative)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
			_last_pos = mb.position
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_apply_look(mm.relative)


func _apply_look(relative: Vector2) -> void:
	var sens: float = 0.0055 * GameState.camera_sensitivity
	yaw -= relative.x * sens
	pitch = clampf(pitch - relative.y * sens, min_pitch, max_pitch)
