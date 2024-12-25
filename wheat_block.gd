extends Node2D
class_name WheatBlock


var sides: Dictionary[Game.Direction, bool] = {
	Game.Direction.UP: true,
	Game.Direction.DOWN: true,
	Game.Direction.LEFT: true,
	Game.Direction.RIGHT: true,
}

@export var sprite: AnimatedSprite2D
@export var debug_line: Line2D
@export var parts: Node2D

@export var parts_to_remove: Dictionary[Game.Direction, Node2D] = {}

var cut_direction: Game.Direction = Game.Direction.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug_line.visible = Global.draw_debug
	Global.draw_debug_toggled.connect(func(v):
		queue_redraw()
		debug_line.visible = v
	)
	#$Good/Parts.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func reset_sides() -> void:
	for side in sides.keys():
		sides.set(side, true)
	update_sprite()
	
func cut(remove: Game.Direction, cut_direction: Game.Direction = Game.Direction.NONE) -> void:
	if cut_direction == Game.Direction.NONE:
		cut_direction = remove
	self.cut_direction = cut_direction
	sides[remove] = false
	update_sprite()

func has_side(side: Game.Direction) -> bool:
	return sides[side]

func update_sprite() -> void:
	
	var count_intact_sides = sides.values().filter(func(v): return v).size()
	
	if count_intact_sides < 4:
		remove_parts(Game.Direction.NONE)
		
	for side in sides.keys():
		if not sides[side]:
			remove_parts(side)
	
	var up := sides[Game.Direction.UP]
	var down := sides[Game.Direction.DOWN]
	var left := sides[Game.Direction.LEFT]
	var right := sides[Game.Direction.RIGHT]
	
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
		4:
			sprite.set_frame_and_progress(0, 0)
	queue_redraw()
			
func remove_parts(dir: Game.Direction) -> void:
	if parts_to_remove.has(dir):
		var part: Node2D = parts_to_remove.get(dir) as Node2D
		if part is WheatPart:
			(part as WheatPart).cut(cut_direction)
		else:
			for child in part.get_children():
				if child is WheatPart:
					(child as WheatPart).cut(cut_direction)
		#parts_to_remove.erase(dir)
	
func _draw() -> void:
	if not Global.draw_debug:
		return
	draw_set_transform(Vector2(8,8))
	
	
	for side in sides.keys():
		draw_circle(Game.dir_to_vec(side) * 3, 2, Color.GREEN if sides[side] else Color.RED)
