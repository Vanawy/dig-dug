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

var grid_coords: Vector2i = Vector2i.ZERO
var current_path: Array[Vector2i] = []
var current_roam_direction = Game.Direction.UP
var global_target_pos: Vector2 = Vector2.ZERO

signal on_death

func get_target() -> Vector2i:
	if current_path.size() > 0:
		return current_path.pop_front()
	return grid_coords
	
func has_path() -> bool:
	return current_path.size() > 0
	
func change_direction() -> void:
	current_roam_direction = PATROL_ORDER[(PATROL_ORDER.find(current_roam_direction) + 1) % PATROL_ORDER.size()]
	queue_redraw()
	

func _ready() -> void:
	current_speed = speed
	current_hp = hp
	stun_indicator.visible = false
	turn_normal()
	
	hitbox.body_entered.connect(func(player: Player):
		if stun_lock.is_stopped():
			player.death()
	)
	
	stun_lock.timeout.connect(func():
		current_speed = speed
		stun_indicator.visible = false
	)
	
	update_path_timer.timeout.connect(update_path)
	
	hit_particles.one_shot = true
	hit_particles.emitting = false
	global_target_pos = global_position
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func hit(dir: Game.Direction) -> bool:
	print("hit")
	
	if is_ghost:
		print("cant hit ghost haha")
		return false
	
	current_speed = 0
	stun_lock.start()
	stun_indicator.visible = true
	hit_particles.restart()
	
	current_hp -= 1
	if current_hp <= 0:
		death()
		
	
	return true

func death() -> void:
	print("enemy died")
	on_death.emit()
	Navigation.visualisation_paths.erase(get_rid())
	queue_free()
	
func turn_into_ghost() -> void:
	is_ghost = true
	normal_sprite.visible = false
	ghost_sprite.visible = true
	
func turn_normal() -> void:
	is_ghost = false
	normal_sprite.visible = true
	ghost_sprite.visible = false
	global_target_pos = global_position
	
func update_path() -> void:
	var path := Navigation.get_path_to_player(grid_coords)
	Navigation.visualisation_paths.set(get_rid(), path)
	current_path = path
	queue_redraw()
		

func _draw() -> void:
	if not Global.draw_debug:
		return
	draw_line(Vector2.ZERO, Game.dir_to_vec(current_roam_direction) * 16, Color.GREEN, 1)
	draw_line(Vector2.ZERO, (get_target() - grid_coords) * 16, Color.RED, 1)
	draw_line(Vector2.ZERO, to_local(global_target_pos), Color.BLUE, 1)
