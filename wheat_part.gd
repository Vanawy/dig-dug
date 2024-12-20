extends Node2D
class_name WheatPart

@export var frame: int = 0
@export var sprite: AnimatedSprite2D
@export var animation: AnimationPlayer

func _ready() -> void:
	sprite.set_frame_and_progress(frame, 0.0)
	animation.seek(randf() * 0.4)
