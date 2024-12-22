extends CharacterBody2D
class_name Enemy

@export var speed_multiplier: float = 0.0


var speed: float = 0
var current_speed: float = 0

@export var hp: int = 99
var current_hp: int = 0

@export_category("Children")
@export var hitbox: Area2D 
@export var stun_lock: Timer
@export var stun_indicator: Control
@export var hp_indicator: Control
@export var hit_particles: CPUParticles2D
@export var update_path_timer: Timer

var grid_coords: Vector2i = Vector2i.ZERO
var current_path: Array[Vector2i] = []

signal on_death

func get_target() -> Vector2i:
	if current_path.size() > 1:
		return current_path[1]
	return grid_coords

func _ready() -> void:
	speed = 0
	current_speed = speed
	current_hp = hp
	stun_indicator.visible = false
	
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
	

func hit(dir: Game.Direction) -> bool:
	print("hit")
	
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
	
	
func update_path() -> void:
	var path := Navigation.get_path_to_player(grid_coords)	
	current_path = path
		
