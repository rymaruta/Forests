extends Node3D
class_name CameraOrbit
## プレイヤー追従 + 右画面スワイプでオービット

@export var target_path: NodePath
@export var distance: float = 7.5
@export var height: float = 3.2
@export var min_pitch: float = -0.55
@export var max_pitch: float = 0.35

var yaw: float = 0.4
var pitch: float = -0.35
var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.current = true


func _process(delta: float) -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		return
	var desired := target.global_position
	desired.y += 1.0
	global_position = global_position.lerp(desired, 1.0 - exp(-8.0 * delta))

	var offset := Vector3(
		sin(yaw) * cos(pitch) * distance,
		height + sin(-pitch) * distance * 0.35,
		cos(yaw) * cos(pitch) * distance
	)
	camera.position = camera.position.lerp(offset, 1.0 - exp(-10.0 * delta))
	camera.look_at(global_position + Vector3(0, 0.6, 0), Vector3.UP)


func _input(event: InputEvent) -> void:
	if GameState.is_menu_open:
		return

	# 右半分のドラッグのみカメラ（左はジョイスティック）
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

	# マウス（エディタ検証用）
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
