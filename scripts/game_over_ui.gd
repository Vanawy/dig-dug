extends Control
class_name GameOverUI

@export_category("Nodes")
@export var animation: AnimationPlayer
@export var restart_button: Button
@export var score: Label
@export var pb_container: Control
@export var pb: Label
@export var is_new_pb: RicherTextLabel
@export var credits_button: Button
@export var back_button: Button
@export var main_container: Control
@export var credits_container: Control
@export var credits_label: RicherTextLabel

func _ready() -> void:
	visible = false
	pb_container.visible = true
	is_new_pb.visible = false
	main_container.visible = true
	credits_container.visible = false
	credits_button.pressed.connect(func():
		main_container.visible = false
		credits_container.visible = true
	)
	back_button.pressed.connect(func():
		main_container.visible = true
		credits_container.visible = false
	)
	
	var file := FileAccess.open(ProjectSettings.globalize_path("res://CREDITS.txt"), FileAccess.READ)
	credits_label.bbcode = file.get_as_text()
	return
	
func game_over(score, pb) -> void:
	animation.play("game_over")
	restart_button.grab_focus()
	self.score.text = str(score)
	self.pb.text = str(pb)
	if score == pb:
		is_new_pb.visible = true
		pb_container.visible = false
	return
