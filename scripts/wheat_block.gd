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
var grid_coords: Vector2i

signal on_side_cut(at: Vector2i, dir: Game.Direction)
signal on_reset(at: Vector2i)

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
	on_reset.emit(grid_coords)
	
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
		on_side_cut.emit(grid_coords, Game.Direction.NONE)
		
	for side in sides.keys():
		if not sides[side]:
			on_side_cut.emit(grid_coords, side)
	
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
			
	
func remove_hitbox() -> void:
	$Hitbox.queue_free()
	
func _draw() -> void:
	if not Global.draw_debug:
		return
	draw_set_transform(Vector2(8,8))
	
	
	for side in sides.keys():
		draw_circle(Game.dir_to_vec(side) * 3, 2, Color.GREEN if sides[side] else Color.RED)
