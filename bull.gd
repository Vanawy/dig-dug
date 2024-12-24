extends CharacterBody2D
class_name Bull

@export_category("Children")
@export var rage_timer: Timer
@export var sprite: AnimatedSprite2D

var speed: float = 0
var a: float = 64

var grid_coords: Vector2i = Vector2i.ZERO
var global_target_pos: Vector2 = Vector2.ZERO

var can_destroy_count: float = 1
var destruction_param: float = 0.8

var is_raged: bool = false
var is_running: bool = false

func _ready() -> void:
	#update_path_timer.timeout.connect(update_path)
	global_target_pos = global_position
	rage_timer.timeout.connect(run)
	collision_mask = Global.clear_mask_bit(collision_mask, Global.Layers.BULLS)
	collision_mask = Global.set_mask_bit(collision_mask, Global.Layers.WALLS)
	
func rage() -> void:
	if is_raged:
		return
	rage_timer.start()
	is_raged = true
	
func run() -> void:
	if is_running:
		return
	collision_mask = Global.set_mask_bit(collision_mask, Global.Layers.BULLS)
	collision_mask = Global.clear_mask_bit(collision_mask, Global.Layers.WALLS)
	is_running = true
	speed = a
	
func stop() -> void:
	collision_mask = Global.clear_mask_bit(collision_mask, Global.Layers.BULLS)
	collision_mask = Global.set_mask_bit(collision_mask, Global.Layers.WALLS)
	global_target_pos = global_position
	is_raged = false
	is_running = false
	can_destroy_count = 1
	
func _physics_process(delta: float) -> void:
	if not is_running:
		return
	speed += a * delta
	can_destroy_count += destruction_param * delta
	move_and_slide()
	var collision := get_last_slide_collision()
	if collision:
		var collider := collision.get_collider()
		if collider is Enemy:
			collider.death()
		if collider is Player:
			collider.death()
			destruction_param = 0
