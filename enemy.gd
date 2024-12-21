extends CharacterBody2D
class_name Enemy

@export var speed_multiplier: float = 0.0

@export_category("Child nodes")
@export var hitbox: Area2D 
@export var stun_lock: Timer
@export var stun_indicator: Node2D

var speed: float = 0
var current_speed: float = 0

var hp: int = 99
var current_hp: int = hp

signal on_death

func _ready() -> void:
	speed = 0
	current_speed = speed
	stun_indicator.visible = false
	
	hitbox.body_entered.connect(func(player: Player):
		if stun_lock.is_stopped():
			player.death()
	)
	
	stun_lock.timeout.connect(func():
		current_speed = speed
		stun_indicator.visible = false
	)
	

func hit(dir: Game.Direction) -> bool:
	print("hit")
	
	current_speed = 0
	stun_lock.start()
	stun_indicator.visible = true
	
	current_hp -= 1
	if current_hp <= 0:
		death()
		
	
	return true

func death() -> void:
	print("enemy died")
	
