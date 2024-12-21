extends CharacterBody2D
class_name Enemy

@export var speed_multiplier: float = 0.0

@export_category("Child nodes")
@export var hitbox: Area2D 

var speed: float = 0

func _ready() -> void:
	speed = 0
	
	hitbox.body_entered.connect(func(player: Player):
		player.death()
	)
		
