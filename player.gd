extends CharacterBody2D
class_name Player

@export var scythe_animation: AnimationPlayer
@export var sprite: AnimatedSprite2D
@export var scythe_pivot: Node2D

var current_direction: Game.Direction = Game.Direction.NONE


func _ready() -> void:
	scythe_pivot.visible = false

func change_direction(dir: Game.Direction) -> void:
	if dir == current_direction:
		return
	current_direction = dir
	match dir:
		Game.Direction.NONE, Game.Direction.UP, Game.Direction.DOWN:
			#sprite.flip_h = false
			sprite.play("idle")
			scythe_pivot.scale.x = 1
		Game.Direction.LEFT:
			sprite.flip_h = false
			scythe_pivot.scale.x = 1
			sprite.play("run")
		Game.Direction.RIGHT:
			sprite.flip_h = true
			scythe_pivot.scale.x = -1
			sprite.play("run")
			
	match dir:
		Game.Direction.UP:
			scythe_pivot.rotation = PI/2
		Game.Direction.DOWN:
			scythe_pivot.rotation = -PI/2
		Game.Direction.NONE:
			pass
		_:
			scythe_pivot.rotation = 0
			
			

func dig(_direction: Game.Direction) -> void:
	scythe_pivot.visible = true
	scythe_animation.play("dig")
	await scythe_animation.animation_finished
	scythe_animation.play("idle")
	scythe_pivot.visible = false



#const SPEED = 32.0
#
#
func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#if direction:
		#velocity = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
