extends Control
class_name PauseUI

@export_category("Nodes")
@export var animation: AnimationPlayer
@export var continue_button: Button

signal continue_pressed

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(func():
		continue_pressed.emit()
	)
	
func pause() -> void:
	animation.play("pause")
	continue_button.grab_focus()
	return
	
func unpause() -> void:
	animation.play_backwards("pause")
	return
