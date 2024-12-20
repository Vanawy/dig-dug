extends Node2D
class_name WheatBlock

var up: bool = true:
	set(v):
		up = v
		update_sprite()
var down: bool = true:
	set(v):
		down = v
		update_sprite()
var left: bool = true:
	set(v):
		left = v
		update_sprite()
var right: bool = true:
	set(v):
		right = v
		update_sprite()

@export var sprite: AnimatedSprite2D
@export var debug_line: Line2D
@export var parts: Node2D

@export var parts_to_remove: Dictionary[Game.Direction, Node2D] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug_line.visible = Global.draw_debug
	Global.draw_debug_toggled.connect(func(v):
		queue_redraw()
		debug_line.visible = v
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_sprite() -> void:
	queue_redraw()
	
	var count_intact_sides = int(up) + int(down) + int(left) + int(right)
	if count_intact_sides < 4:
		remove_parts(Game.Direction.NONE)
	if not up:
		remove_parts(Game.Direction.UP)
	if not down:
		remove_parts(Game.Direction.DOWN)
	if not left:
		remove_parts(Game.Direction.LEFT)
	if not right:
		remove_parts(Game.Direction.RIGHT)
	
	match count_intact_sides:
		0: 
			sprite.set_frame_and_progress(5, 0)
		1:
			sprite.set_frame_and_progress(2, 0)
			if up:
				sprite.rotation = -PI/2
			if down:
				sprite.rotation = PI/2
			if right:
				sprite.rotation = 0
			if left:
				sprite.rotation = PI
		2: 
			if up and down:
				sprite.set_frame_and_progress(1, 0)
			if left and right:
				sprite.set_frame_and_progress(1, 0)
				sprite.rotation = PI/2
			if left and up:
				sprite.set_frame_and_progress(3, 0)
				sprite.rotation = PI
			if right and up:
				sprite.set_frame_and_progress(3, 0)
				sprite.rotation = -PI/2
			if right and down:
				sprite.set_frame_and_progress(3, 0)
				sprite.rotation = 0
			if left and down:
				sprite.set_frame_and_progress(3, 0)
				sprite.rotation = PI/2
				
		3:
			sprite.set_frame_and_progress(4, 0)
			if not up:
				sprite.rotation = PI/2
			if not down:
				sprite.rotation = -PI/2
			if not right:
				sprite.rotation = PI
			if not left:
				sprite.rotation = 0
			
func remove_parts(dir: Game.Direction) -> void:
	if parts_to_remove.has(dir):
		(parts_to_remove.get(dir) as Node2D).queue_free()
		parts_to_remove.erase(dir)
	
func _draw() -> void:
	if not Global.draw_debug:
		return
	draw_set_transform(Vector2(8,8))
	draw_circle(Vector2.UP * 3, 2, Color.GREEN if up else Color.RED)
	draw_circle(Vector2.DOWN * 3, 2, Color.GREEN if down else Color.RED)
	draw_circle(Vector2.LEFT * 3, 2, Color.GREEN if left else Color.RED)
	draw_circle(Vector2.RIGHT * 3, 2, Color.GREEN if right else Color.RED)
