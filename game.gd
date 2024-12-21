extends Node2D
class_name Game

enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

var direction: Direction = Direction.NONE

const FIELD_CENTER: Vector2i = Vector2i(6,7)

const DIG_OFFSET: float = 4

@export var field: TileMapLayer
@export var player: Player
@export var skip_intro: bool = true

var is_player_intro_done: bool = false


var target_coords: Vector2i = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_coords = FIELD_CENTER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var player_corrds := field.local_to_map(to_local(player.global_position))
	
	if not is_player_intro_done:
		direction = Direction.DOWN
		if player_corrds == target_coords:
			is_player_intro_done = true
			direction = Direction.NONE
	
	
	destroy_current_block(player_corrds)
	
	match direction:
		Direction.UP, Direction.DOWN:
			var k := TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE
			if direction == Direction.DOWN:
				k = TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE
			if is_player_intro_done:
				target_coords = field.get_neighbor_cell(player_corrds, k)
			move_player_to_target(player.speed * delta)

		Direction.LEFT, Direction.RIGHT:
			var k := TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE
			if direction == Direction.RIGHT:
				k = TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE
			if is_player_intro_done:
				target_coords = field.get_neighbor_cell(player_corrds, k)
			move_player_to_target(player.speed * delta)
		
		Direction.NONE:
			player.change_direction(Direction.NONE)
			
		
# Move player along grid tilemap grid throug tiles centers
func move_player_to_target(speed) -> void:
	if skip_intro and not is_player_intro_done:
		speed *= 10
		
	var old_player_pos = player.position
	
	var target_pos := field.map_to_local(target_coords)
	match direction:
		Direction.UP, Direction.DOWN:
			if not is_equal_approx(to_local(player.position).x, target_pos.x):
				player.position.x = move_toward(player.position.x, target_pos.x, speed)
			else:
				player.position.y = move_toward(player.position.y, target_pos.y, speed)
				
		Direction.LEFT, Direction.RIGHT:
			if not is_equal_approx(to_local(player.position).y, target_pos.y):
				player.position.y = move_toward(player.position.y, target_pos.y, speed)
			else:
				player.position.x = move_toward(player.position.x, target_pos.x, speed)
	
	var actual_direction := Direction.NONE
	if player.position.x > old_player_pos.x:
		actual_direction = Direction.RIGHT
	elif player.position.x < old_player_pos.x:
		actual_direction = Direction.LEFT
	elif player.position.y > old_player_pos.y:
		actual_direction = Direction.DOWN
	elif player.position.y < old_player_pos.y:
		actual_direction = Direction.UP
	
	player.change_direction(actual_direction)
		
func destroy_current_block(block_coords: Vector2i) -> void:
	var block: WheatBlock = get_block_at_coords(block_coords)
	if not is_instance_valid(block):
		return
	block.cut_direction = direction
	var pos_dif = block.to_local(player.global_position) - Vector2(8, 8)
		
	#region Block destruction scary match
	#print(pos_dif)
	match direction:
		Direction.UP, Direction.DOWN:
			if block.down and pos_dif.y > DIG_OFFSET:
				block.down = false
				player.dig(direction)
				var n := get_block_at_coords(block_coords + Vector2i.DOWN)
				if is_instance_valid(n):
					n.cut_direction = direction
					n.up = false
			if block.up and pos_dif.y < -DIG_OFFSET:
				block.up = false
				player.dig(direction)
				var n := get_block_at_coords(block_coords + Vector2i.UP)
				if is_instance_valid(n):
					n.cut_direction = direction
					n.down = false
		Direction.LEFT, Direction.RIGHT:
			if block.right and pos_dif.x > DIG_OFFSET:
				block.right = false
				player.dig(direction)
				var n := get_block_at_coords(block_coords + Vector2i.RIGHT)
				if is_instance_valid(n):
					n.cut_direction = direction
					n.left = false
			if block.left and pos_dif.x < -DIG_OFFSET:
				block.left = false
				player.dig(direction)
				var n := get_block_at_coords(block_coords + Vector2i.LEFT)
				if is_instance_valid(n):
					n.cut_direction = direction
					n.right = false
	#endregion
		
func get_block_at_coords(block_coords: Vector2i) -> WheatBlock:
	
	var global_pos := to_global(field.map_to_local(block_coords))
	
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(global_pos, global_pos + Vector2.DOWN, (1 << Global.Layers.WHEAT), [
		player.get_rid()
	])
	params.hit_from_inside = true
	params.collide_with_areas = true
	
	var result := space_state.intersect_ray(params)
	
	#print(result)
	if not result.has('collider') or not is_instance_valid(result['collider']):
		return null
	var collider: Node2D = result['collider']
	if not collider.get_parent() is WheatBlock:
		return null
	
	return collider.get_parent()
	
	
func _unhandled_input(event: InputEvent) -> void:
	
	if is_player_intro_done and not player.is_dead:
		if event.is_action_pressed("ui_up"):
			direction = Direction.UP
		if event.is_action_pressed("ui_down"):
			direction = Direction.DOWN
		if event.is_action_pressed("ui_right"):
			direction = Direction.RIGHT
		if event.is_action_pressed("ui_left"):
			direction = Direction.LEFT
			
		if event.is_action_released("ui_up") and direction == Direction.UP \
			or event.is_action_released("ui_down") and direction == Direction.DOWN \
			or event.is_action_released("ui_right") and direction == Direction.RIGHT \
			or event.is_action_released("ui_left") and direction == Direction.LEFT:

			direction = Direction.NONE
			
		if event.is_action_pressed("ui_accept"):
			player.attack()
	
	if event.as_text() == 'F2' and event.is_pressed():
		get_tree().reload_current_scene()
		
	if event.as_text() == 'F3' and event.is_pressed():
		Global.draw_debug = !Global.draw_debug
		
	if event.as_text() == 'F4' and event.is_pressed():
		player.death()
		
	
	
static func dir_to_vec(dir: Direction) -> Vector2:
	match dir:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT

	return Vector2.ZERO
