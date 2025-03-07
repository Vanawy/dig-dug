extends CharacterBody2D
class_name Player

const SPEED: float = 32

var speed: float = SPEED


var in_direction: Game.Direction = Game.Direction.NONE
var priority_direction: Game.Direction = Game.Direction.NONE
var look_direction: Game.Direction = Game.Direction.RIGHT
var move_direction: Game.Direction = Game.Direction.NONE

var move_input: Vector2 = Vector2.ZERO

@export_category("Nodes")
@export var rays: Dictionary[Game.Direction, RayCast2D] = {}
@export var scythe_animation: AnimationPlayer
@export var sprite: AnimatedSprite2D
@export var scythe_pivot: Node2D
@export var attack_lock: Timer
@export var attack_particles: CPUParticles2D
@export var miss_particles: CPUParticles2D
@export var grid_coords: GridCoordinates
@export_category("Audio")
@export var hit_sound: AudioStreamPlayer2D
@export var miss_sound: AudioStreamPlayer2D
@export var death_sound: AudioStreamPlayer2D
@export var cut_sound: AudioStreamPlayer2D

var is_dead: bool = true
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
	miss_particles.one_shot = true
	miss_particles.emitting = false
	respawn()
	
func death() -> void:
	if is_dead:
		return
	is_dead = true
	speed = 0
	collision_layer = Global.clear_mask_bit(collision_layer, Global.Layers.PLAYER)
	sprite.play("death")
	death_sound.play()
	await sprite.animation_finished
	on_death.emit()
	
func respawn() -> void:
	if not is_dead:
		return
	sprite.play("idle")
	death_sound.stop()
	speed = SPEED
	is_dead = false
	collision_layer = Global.set_mask_bit(collision_layer, Global.Layers.PLAYER)
	
	
func attack() -> void:
	
	if is_dead:
		return
	
	if not attack_lock.is_stopped():
		print("can't attack for: " + str(attack_lock.time_left))
		return
	var attack_ray := rays.get(look_direction) as RayCast2D
	if not attack_ray.is_colliding():
		play_miss_effects()
		return
		
	var enemy := attack_ray.get_collider().get_parent() as Enemy
	if not enemy is Enemy:
		play_miss_effects()
		return
	
	if enemy.hit(look_direction):
		attack_lock.start()
		sprite.play("attack")
		speed = 0
		attack_particles.direction = Game.dir_to_vec(look_direction)
		attack_particles.restart()
		hit_sound.play()
	else:
		play_miss_effects()
		
func play_miss_effects() -> void:
	sprite.play("attack")
	miss_particles.direction = Game.dir_to_vec(look_direction)
	miss_particles.restart()
	miss_sound.play()
	

func get_target() -> Vector2i:
	return grid_coords.at + Vector2i(Game.dir_to_vec(in_direction))

func update_sprites(dir: Game.Direction) -> void:
	if is_dead or dir == move_direction:
		return
		
	move_direction = dir
		
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
	cut_sound.play()
	scythe_animation.play("dig")
	await scythe_animation.animation_finished
	scythe_animation.play("idle")
	scythe_pivot.visible = false

#const SPEED = 32.0
#
#
func _physics_process(delta: float) -> void:
	
	Navigation.update_player_pos(grid_coords.at)

	move_and_slide()
	queue_redraw()
	
func _draw() -> void:
	#draw_line(Vector2.ZERO, move_input * 16, Color.BLUE, 1)
	return
		
func _process(delta: float) -> void:
	
	move_input = Input.get_vector("player_left", "player_right", "player_up", "player_down", 0.2)
	
	in_direction = Game.vec_to_dir(move_input, priority_direction)
	
	if in_direction != Game.Direction.NONE:
		look_direction = in_direction

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player_up"):
		priority_direction = Game.Direction.UP
	if event.is_action_pressed("player_down"):
		priority_direction = Game.Direction.DOWN
	if event.is_action_pressed("player_right"):
		priority_direction = Game.Direction.RIGHT
	if event.is_action_pressed("player_left"):
		priority_direction = Game.Direction.LEFT
		
	if event.is_action_pressed("player_attack"):
		attack()
