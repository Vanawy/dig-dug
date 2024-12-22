extends Camera2D
class_name GameCamera

@export var move_trigger: Area2D

func _ready() -> void:
	move_trigger.body_entered.connect(func(bode: Node2D):
		move_camera()
	)
	
func move_camera() -> void:
	create_tween().tween_property(self, "position", Vector2.ZERO, 1.0)
	if is_instance_valid(move_trigger):
		move_trigger.queue_free()
