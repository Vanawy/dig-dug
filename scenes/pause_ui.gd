extends Control
class_name PauseUI

@export_category("Nodes")
@export var animation: AnimationPlayer
@export var continue_button: Button
@export var restart_button: Button

func _ready() -> void:
	visible = false
	
func pause() -> void:
	animation.play("pause")
	continue_button.grab_focus()
	return
	
func unpause() -> void:
	animation.play_backwards("pause")
	return
