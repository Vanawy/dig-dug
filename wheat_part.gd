extends CharacterBody2D
class_name WheatPart


enum Type {
	WHEAT,
	CORN
}

@export var frame: int = 0
@export var sprites: Dictionary[Type, AnimatedSprite2D] = {}
@export var animation: AnimationPlayer

@export var type: Type = Type.WHEAT


func _ready() -> void:
	for sprite in sprites.values():
		sprite.visible = false
		
	var sprite := sprites.get(type) as AnimatedSprite2D
	sprite.set_frame_and_progress(frame, 0.0)
	sprite.visible = true
	animation.seek(randf() * 0.4)
	
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func cut(dir: Game.Direction):
	
	velocity = Game.dir_to_vec(dir) * 100
	
	if randf() > 0.5:
		animation.play("cut")
	else:
		animation.play("cut_2")
