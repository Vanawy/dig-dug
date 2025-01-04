extends Control
class_name GameOverUI

@export_category("Nodes")
@export var animation: AnimationPlayer
@export var restart_button: Button
@export var score: Label
@export var pb_container: Control
@export var pb: Label
@export var is_new_pb: RicherTextLabel

func _ready() -> void:
	visible = false
	pb_container.visible = true
	is_new_pb.visible = false
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
