extends CharacterBody2D
class_name Enemy


const PATROL_ORDER: Array[Game.Direction] = [
	Game.Direction.UP, 
	Game.Direction.RIGHT, 
	Game.Direction.DOWN, 
	Game.Direction.LEFT,
]


@export var speed_multiplier: float = 0.0
@export var speed: float = 0
var current_speed: float = 0

@export var hp: int = 99
var current_hp: int = 0

var is_dead = false
var is_ghost = false

@export_category("Children")
@export var hitbox: Area2D 
@export var stun_lock: Timer
@export var stun_indicator: Control
@export var hp_indicator: Control
@export var hit_particles: CPUParticles2D
@export var update_path_timer: Timer

@export var normal_sprite: AnimatedSprite2D
@export var ghost_sprite: AnimatedSprite2D

@export var hit_sfx: AudioStreamPlayer2D
@export var ghost_sfx: AudioStreamPlayer2D

@export var grid_coords: GridCoordinates

var global_spawn_pos: Vector2 = Vector2.ZERO
var current_path: Array[Vector2i] = []
var current_roam_direction = Game.Direction.UP
var global_target_pos: Vector2 = Vector2.ZERO

signal on_death

func get_target() -> Vector2i:
	if current_path.size() > 0:
		return current_path.pop_front()
	return grid_coords.at
	
func has_path() -> bool:
	return current_path.size() > 0
	
func change_direction() -> void:
	current_roam_direction = PATROL_ORDER[(PATROL_ORDER.find(current_roam_direction) + 1) % PATROL_ORDER.size()]
	queue_redraw()
	
func _process(delta: float) -> void:
	if is_dead:
		return
	if not is_ghost:
		var pos_diff := global_target_pos - global_position
		
		# there should be a better way but idk rn lol
		var n := pos_diff.normalized()
		if n.x > 0.5:
			normal_sprite.play("left_right")
			normal_sprite.flip_h = true
		if n.x < -0.5:
			normal_sprite.play("left_right")
			normal_sprite.flip_h = false
		if n.y > 0.5:
			normal_sprite.flip_h = false
			normal_sprite.play("down")
		if n.y < -0.5:
			normal_sprite.flip_h = false
			normal_sprite.play("up")
			
	

func _ready() -> void:
	current_speed = speed
	current_hp = hp
	stun_indicator.visible = false
	turn_normal()
	normal_sprite.material.set("shader_parameter/hp_ratio", 1.0)
	current_roam_direction = PATROL_ORDER[Global.rng.randi_range(0, PATROL_ORDER.size() - 1)]
	
	hitbox.body_entered.connect(func(player: Player):
		if stun_lock.is_stopped():
			player.death()
	)
	
	stun_lock.timeout.connect(func():
		if is_dead:
			return
		current_speed = speed
		stun_indicator.visible = false
		normal_sprite.play()
		ghost_sfx.stream_paused = false
	)
	
	update_path_timer.timeout.connect(update_path)
	
	hit_particles.one_shot = true
	hit_particles.emitting = false
	global_target_pos = global_position
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func hit(dir: Game.Direction) -> bool:
	print("hit")
	
	if is_dead:
		return false
	
	current_speed = 0
	stun_lock.start()
	normal_sprite.pause()
	stun_indicator.visible = true
	ghost_sfx.stream_paused = true
	hit_particles.restart()
	hit_sfx.play()
	
	current_hp -= 1
	
	normal_sprite.material.set("shader_parameter/hp_ratio", float(current_hp) / float(hp))
	if current_hp <= 0:
		death()
		
	
	return true

func death() -> void:
	if is_dead:
		return
	turn_normal()
	is_dead = true
	current_speed = 0
	#hitbox.position = Vector2(10000, 10000)
	collision_layer = Global.clear_mask_bit(collision_layer, Global.Layers.ENEMIES)
	print("enemy died")
	on_death.emit()
	Navigation.visualisation_paths.erase(get_rid())
	normal_sprite.play("death")
	normal_sprite.animation_finished.connect(queue_free)
	
func turn_into_ghost() -> void:
	is_ghost = true
	normal_sprite.visible = false
	ghost_sprite.visible = true
	ghost_sfx.play()
	collision_mask = Global.clear_mask_bit(collision_mask, Global.Layers.WALLS)
	
func turn_normal() -> void:
	ghost_sfx.stop()
	is_ghost = false
	normal_sprite.visible = true
	ghost_sprite.visible = false
	global_target_pos = global_position
	collision_mask = Global.set_mask_bit(collision_mask, Global.Layers.WALLS)
	
func update_path() -> void:
	var path := Navigation.get_path_to_player(grid_coords.at)
	Navigation.visualisation_paths.set(get_rid(), path)
	current_path = path
	queue_redraw()

func respawn() -> void:
	turn_normal()
	current_path = []
	global_position = global_spawn_pos
	global_target_pos = global_spawn_pos
	grid_coords.at = Vector2i(-1, -1)
		
func _draw() -> void:
	if not Global.draw_debug:
		return
	draw_line(Vector2.ZERO, Game.dir_to_vec(current_roam_direction) * 16, Color.GREEN, 1)
	draw_line(Vector2.ZERO, (get_target() - grid_coords.at) * 16, Color.RED, 1)
	draw_line(Vector2.ZERO, to_local(global_target_pos), Color.BLUE, 1)
