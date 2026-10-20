extends Control
class_name VirtualJoystick
## 左下の仮想スティック（セーフエリア対応）

signal move_vector_changed(vector: Vector2)

@export var knob_path: NodePath
@export var base_path: NodePath
@export var max_radius: float = 56.0

var _active: bool = false
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _value: Vector2 = Vector2.ZERO

@onready var _base: Control = get_node(base_path) if base_path else $Base
@onready var _knob: Control = get_node(knob_path) if knob_path else $Base/Knob


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reset_knob()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_active = true
			_touch_index = st.index
			_origin = _base.position + _base.size * 0.5
			_update_knob(st.position)
			accept_event()
		elif st.index == _touch_index:
			_active = false
			_touch_index = -1
			_value = Vector2.ZERO
			_reset_knob()
			move_vector_changed.emit(_value)
			accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _active and sd.index == _touch_index:
			_update_knob(sd.position)
			accept_event()
	# マウス互換
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_active = true
				_origin = _base.position + _base.size * 0.5
				_update_knob(mb.position)
			else:
				_active = false
				_value = Vector2.ZERO
				_reset_knob()
				move_vector_changed.emit(_value)
	elif event is InputEventMouseMotion and _active:
		_update_knob((event as InputEventMouseMotion).position)


func _update_knob(local_pos: Vector2) -> void:
	var center := _base.position + _base.size * 0.5
	var delta := local_pos - center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	_knob.position = _base.size * 0.5 - _knob.size * 0.5 + delta
	_value = delta / max_radius
	# UI座標: 上が-Yなのでゲーム用にY反転しない（カメラ相対で -y を forward に使う）
	move_vector_changed.emit(_value)


func _reset_knob() -> void:
	_knob.position = _base.size * 0.5 - _knob.size * 0.5


func get_value() -> Vector2:
	return _value
