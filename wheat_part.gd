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

var is_alive: bool = true

var initial_position: Vector2

func _ready() -> void:
	initial_position = position
	for sprite in sprites.values():
		sprite.visible = false
		
	var sprite := sprites.get(type) as AnimatedSprite2D
	sprite.set_frame_and_progress(frame, 0.0)
	sprite.visible = true
	animation.seek(randf() * 0.4)
	
	
func _physics_process(delta: float) -> void:
	if not is_alive:
		move_and_slide()

func cut(dir: Game.Direction):
	
	velocity = Game.dir_to_vec(dir) * 100
	is_alive = false
	
	if randf() > 0.5:
		animation.play("cut")
	else:
		animation.play("cut_2")
		
func disable() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false

func reset() -> void:
	position = initial_position
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	is_alive = true
	animation.play("RESET")
	await animation.animation_finished
	animation.play("wind")
	animation.seek(randf() * 0.4)
