extends Control
signal close_requested


func _ready() -> void:
	$Panel/OkButton.pressed.connect(func(): close_requested.emit())
