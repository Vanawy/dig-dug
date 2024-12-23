extends CharacterBody2D
class_name Player

const SPEED: float = 32

var speed: float = SPEED


var move_direction: Game.Direction = Game.Direction.NONE
var look_direction: Game.Direction = Game.Direction.RIGHT

@export_category("Children")
@export var rays: Dictionary[Game.Direction, RayCast2D] = {}
@export var scythe_animation: AnimationPlayer
@export var sprite: AnimatedSprite2D
@export var scythe_pivot: Node2D
@export var attack_lock: Timer
@export var attack_particles: CPUParticles2D

var is_dead: bool = false
signal on_death

func _ready() -> void:
	scythe_pivot.visible = false
	attack_lock.timeout.connect(func():
		if is_dead:
			return
		sprite.play("idle")
		speed = SPEED
	)
	attack_particles.one_shot = true
	attack_particles.emitting = false
	
func death() -> void:
	if is_dead:
		return
	on_death.emit()
	sprite.play("death")
	is_dead = true
	speed = 0
	
func attack() -> void:
	if not attack_lock.is_stopped():
		print("can't attack for: " + str(attack_lock.time_left))
		return
	var attack_ray := rays.get(look_direction) as RayCast2D
	if not attack_ray.is_colliding():
		print("miss - " + str(Game.Direction.find_key(look_direction)))
		return
		
	var enemy := attack_ray.get_collider().get_parent() as Enemy
	if not enemy is Enemy:
		print("Hit (not enemy) - " + str(Game.Direction.find_key(look_direction)))
		return
	
	if enemy.hit(look_direction):
		attack_lock.start()
		sprite.play("attack")
		speed = 0
		attack_particles.direction = Game.dir_to_vec(look_direction)
		attack_particles.restart()

func change_direction(dir: Game.Direction) -> void:
	if is_dead or dir == move_direction:
		return
		
	move_direction = dir
	if dir != Game.Direction.NONE:
		look_direction = dir
		
	if is_equal_approx(speed, 0):
		return
		
	match move_direction:
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
			
	match move_direction:
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
