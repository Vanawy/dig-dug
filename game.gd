extends Node2D
class_name Game

enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

var direction: Direction = Direction.NONE

const FIELD_CENTER: Vector2i = Vector2i(5,6)

const DIG_OFFSET: float = 4

@export var skip_intro: bool = true
@export_category("Spawn Points")
var rock_spawns: Array[SpawnPoint] = []
var enemy_spawns: Array[SpawnPoint] = []


@export_category("Children")
@export var field: TileMapLayer
@export var player: Player
@export var game_camera: GameCamera

var is_player_intro_done: bool = false
var target_coords: Vector2i = Vector2.ZERO

var tile_size: Vector2 = Vector2(Global.TILE_SIZE, Global.TILE_SIZE)

var rocks_amount: int = 2
var enemies_amount: int = 3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_coords = FIELD_CENTER
	if skip_intro:
		game_camera.position = Vector2.ZERO
		game_camera.move_camera()
		
	var spawns = get_tree().get_nodes_in_group("spawn") as Array[SpawnPoint]
	for spawn in spawns:
		if spawn.type == SpawnPoint.Type.ROCK:
			rock_spawns.push_back(spawn)
		else:
			enemy_spawns.push_back(spawn)
			
	spawn_enemies.call_deferred()
	
	
func spawn_enemies() -> void:
	rock_spawns.shuffle()
	for i in rocks_amount:
		var spawn := rock_spawns.pop_back() as SpawnPoint
		var coords = global_to_coords(spawn.global_position)
		destroy_selected_block(coords, Direction.DOWN, false)
		var rock = preload("res://rock.tscn").instantiate()
		rock.global_position = spawn.global_position
		player.add_sibling(rock) 
		
	enemy_spawns.shuffle()
	for i in enemies_amount:
		var spawn := enemy_spawns.pop_back() as SpawnPoint
		var coords = global_to_coords(spawn.global_position)
		var type := spawn.type
		if type == SpawnPoint.Type.ANY:
			type = [SpawnPoint.Type.HORIZONTAL, SpawnPoint.Type.VERTICAL].pick_random()
		if type == SpawnPoint.Type.HORIZONTAL:
			destroy_selected_block(coords, Direction.LEFT)
			destroy_selected_block(coords, Direction.RIGHT)
		if type == SpawnPoint.Type.VERTICAL:
			destroy_selected_block(coords, Direction.UP)
			destroy_selected_block(coords, Direction.DOWN)
			
		var rock = preload("res://enemy.tscn").instantiate()
		rock.global_position = spawn.global_position
		player.add_sibling(rock) 
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func global_to_coords(pos: Vector2) -> Vector2i:
	return field.local_to_map(field.to_local(pos + Vector2(0, tile_size.y)))

func _physics_process(delta: float) -> void:
	var player_coords := global_to_coords(player.global_position)
	
	if not is_player_intro_done:
		direction = Direction.DOWN
		if player_coords == target_coords:
			is_player_intro_done = true
			var target_pos := to_global(field.map_to_local(target_coords)) + tile_size
			player.global_position = target_pos
			direction = Direction.NONE
			destroy_selected_block(FIELD_CENTER, Direction.LEFT)
			destroy_selected_block(FIELD_CENTER, Direction.RIGHT)
	
	destroy_current_block(player_coords)
	
	match direction:
		Direction.UP, Direction.DOWN:
			var k := TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE
			if direction == Direction.DOWN:
				k = TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE
			if is_player_intro_done:
				target_coords = field.get_neighbor_cell(player_coords, k)
			move_player_to_target(player.speed * delta)

		Direction.LEFT, Direction.RIGHT:
			var k := TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE
			if direction == Direction.RIGHT:
				k = TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE
			if is_player_intro_done:
				target_coords = field.get_neighbor_cell(player_coords, k)
			move_player_to_target(player.speed * delta)
		
		Direction.NONE:
			player.change_direction(Direction.NONE)
			
		
# Move player along grid tilemap grid throug tiles centers
func move_player_to_target(speed) -> void:
	if skip_intro and not is_player_intro_done:
		speed *= 20
		
	var old_player_pos = player.global_position
	
	var target_pos := to_global(field.map_to_local(target_coords)) + tile_size
	
	#print("target: " + str(target_pos) + " pl: " + str(old_player_pos))
	match direction:
		Direction.UP, Direction.DOWN:
			if not is_equal_approx(old_player_pos.x, target_pos.x):
				player.global_position.x = move_toward(old_player_pos.x, target_pos.x, speed)
			else:
				player.global_position.y = move_toward(old_player_pos.y, target_pos.y, speed)
				
		Direction.LEFT, Direction.RIGHT:
			if not is_equal_approx(old_player_pos.y, target_pos.y):
				player.global_position.y = move_toward(old_player_pos.y, target_pos.y, speed)
			else:
				player.global_position.x = move_toward(old_player_pos.x, target_pos.x, speed)
	
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
	var pos_dif = block.to_local(player.global_position) - (tile_size / 2)
	
	var cut_dir := Direction.NONE
	
	match direction:
		Direction.NONE:
			return
		Direction.UP, Direction.DOWN:
			if block.has_side(Direction.DOWN) and pos_dif.y > DIG_OFFSET:
				cut_dir = Direction.DOWN
			if block.has_side(Direction.UP) and pos_dif.y < -DIG_OFFSET:
				cut_dir = Direction.UP
		Direction.LEFT, Direction.RIGHT:
			if block.has_side(Direction.RIGHT) and pos_dif.x > DIG_OFFSET:
				cut_dir = Direction.RIGHT
			if block.has_side(Direction.LEFT) and pos_dif.x < -DIG_OFFSET:
				cut_dir = Direction.LEFT
	
	if cut_dir != Direction.NONE:
		block.cut(cut_dir)
		player.dig(direction)
		var n := get_block_at_coords(block_coords + Vector2i(dir_to_vec(cut_dir)))
		if is_instance_valid(n):
			n.cut(dir_invert(cut_dir), cut_dir)
			
			
func destroy_selected_block(at: Vector2i, side: Direction, destroy_neighbor: bool = true) -> void:
	if side == Direction.NONE:
		return
	var block: WheatBlock = get_block_at_coords(at)
	if not is_instance_valid(block):
		return
	
	block.cut(side)
	if destroy_neighbor:
		var n := get_block_at_coords(at + Vector2i(dir_to_vec(side)))
		if is_instance_valid(n):
			n.cut(dir_invert(side), side)
	
	
		
func get_block_at_coords(block_coords: Vector2i) -> WheatBlock:
	
	var global_pos := to_global(field.map_to_local(block_coords)) + tile_size
	
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
				
	if not is_player_intro_done:
		if event.is_action_pressed("ui_accept"):
			skip_intro = true
			game_camera.position = Vector2.ZERO
			game_camera.move_camera()
	
	if event.as_text() == 'F2' and event.is_pressed():
		get_tree().reload_current_scene()
		
	if event.as_text() == 'F3' and event.is_pressed():
		Global.draw_debug = !Global.draw_debug
		
	if event.as_text() == 'F4' and event.is_pressed():
		player.death()



static func dir_invert(dir: Direction) -> Direction:
	match dir:
		Direction.UP:
			return Direction.DOWN
		Direction.DOWN:
			return Direction.UP
		Direction.LEFT:
			return Direction.RIGHT
		Direction.RIGHT:
			return Direction.LEFT

	return Direction.NONE
	
	
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
