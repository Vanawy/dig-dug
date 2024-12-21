extends CharacterBody2D
class_name WheatPart

@export var frame: int = 0
@export var sprite: AnimatedSprite2D
@export var animation: AnimationPlayer

func _ready() -> void:
	sprite.set_frame_and_progress(frame, 0.0)
	animation.seek(randf() * 0.4)
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func cut(dir: Game.Direction):
	
	velocity = Game.dir_to_vec(dir) * 200
	
	if randf() > 0.5:
		animation.play("cut")
	else:
		animation.play("cut_2")
