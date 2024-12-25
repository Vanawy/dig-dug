extends Node2D
class_name Game

enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

var direction: Direction = Direction.NONE

const FIELD_CENTER: Vector2i = Vector2i(5,6)
const PLAYER_SPAWN: Vector2i = Vector2i(5, -1)

@export var field_size: Vector2i = Vector2i(11, 12)

const DIG_OFFSET: float = 4

@export var skip_intro: bool = true

@export var ghost_probability: float = 0.03

const MAX_HP: int = 3

var player_health: int = 0:
	set(v):
		player_health = v
		game_ui.player_hp = player_health
		
var level: int = 0

@export_category("Spawn Points")
var bull_spawns: Array[SpawnPoint] = []
var enemy_spawns: Array[SpawnPoint] = []

@export_category("Children")
@export var field: TileMapLayer
@export var player: Player
@export var game_camera: GameCamera
@export var game_ui: GameUI

var is_player_intro_done: bool = false
var target_coords: Vector2i = Vector2.ZERO

var tile_size: Vector2 = Vector2(Global.TILE_SIZE, Global.TILE_SIZE)

var bulls_amount: int = 3#2
var enemies_amount: int = 3

var grid: Dictionary[Vector2i, WheatBlock] = {}

var enemies: Array[Enemy] = []
var bulls: Array[Bull] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level = 1
	start_level()
	player_health = MAX_HP
		
	var spawns = get_tree().get_nodes_in_group("spawn") as Array[SpawnPoint]
	for spawn in spawns:
		if spawn.type == SpawnPoint.Type.ROCK:
			bull_spawns.push_back(spawn)
		else:
			enemy_spawns.push_back(spawn)
			
func start_level() -> void:
	player_health -= 1
	# remove old enemies
	for node in enemies + bulls:
		node.queue_free()
		
	for i in field_size.x + 1:
		for j in field_size.y + 1:
			var block := get_block_at_coords(Vector2i(i, j))
			if is_instance_valid(block):
				block.reset_sides()
	get_tree().call_group("wheat_part", "reset")
	
	Navigation.field_size = field_size
	Navigation.navigation.clear()
	Navigation.visualisation_paths.clear()
	spawn_enemies.call_deferred()
	
	respawn_player()
	if level != 1 or skip_intro:
		game_camera.position = Vector2.ZERO
		game_camera.move_camera()

func respawn_player() -> void:
	is_player_intro_done = false
	target_coords = FIELD_CENTER
	player.global_position = coords_to_global(PLAYER_SPAWN)

func spawn_enemies() -> void:
	var spawns := bull_spawns.duplicate()
	spawns.shuffle()
	for i in bulls_amount:
		var spawn := spawns.pop_back() as SpawnPoint
		var coords = global_to_coords(spawn.global_position)
		destroy_selected_block(coords, Direction.DOWN, false)
		Navigation.set_disabled(coords, true)
		var bull = preload("res://bull.tscn").instantiate()
		bull.global_position = spawn.global_position
		player.add_sibling(bull) 
		bulls.append(bull)
		
	spawns = enemy_spawns.duplicate()
	spawns.shuffle()
	for i in enemies_amount:
		var spawn := spawns.pop_back() as SpawnPoint
		var coords = global_to_coords(spawn.global_position)
		var type := spawn.type
		if type == SpawnPoint.Type.ANY:
			type = [SpawnPoint.Type.HORIZONTAL, SpawnPoint.Type.VERTICAL].pick_random()
			
		var offset: int = floor(randf() * spawn.size) - ceil(spawn.size / 2)
		var pos_offset: Vector2 = Vector2.ZERO
		if type == SpawnPoint.Type.HORIZONTAL:
			pos_offset.x = offset
			destroy_selected_block(coords, Direction.LEFT)
			destroy_selected_block(coords, Direction.RIGHT)
			if spawn.size == SpawnPoint.Size.BIG:
				destroy_selected_block(coords + Vector2i.LEFT, Direction.LEFT)
				destroy_selected_block(coords + Vector2i.RIGHT, Direction.RIGHT)
		if type == SpawnPoint.Type.VERTICAL:
			pos_offset.y = offset
			destroy_selected_block(coords, Direction.UP)
			destroy_selected_block(coords, Direction.DOWN)
			if spawn.size == SpawnPoint.Size.BIG:
				destroy_selected_block(coords + Vector2i.UP, Direction.UP)
				destroy_selected_block(coords + Vector2i.DOWN, Direction.DOWN)
			
		#var enemy = preload("res://enemy.tscn").instantiate()
		var enemy = preload("res://enemy_priest.tscn").instantiate()
		enemy.global_position = spawn.global_position + pos_offset * tile_size
		enemy.grid_coords = global_to_coords(enemy.global_position)
		player.add_sibling(enemy) 
		enemies.append(enemy)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	pass

func global_to_coords(pos: Vector2) -> Vector2i:
	return field.local_to_map(field.to_local(pos + Vector2(0, tile_size.y)))
	
func coords_to_global(coords: Vector2i) -> Vector2:
	return to_global(field.map_to_local(coords)) + tile_size

func _physics_process(delta: float) -> void:
	var player_coords := global_to_coords(player.global_position)
	Navigation.update_player_pos(player_coords)
	#print(Navigation.player_pos_id)
		
	if is_player_intro_done:
		move_enemies(delta)
		move_bulls(delta)
	
	if not is_player_intro_done:
		direction = Direction.DOWN
		if player_coords == target_coords:
			is_player_intro_done = true
			var target_pos := to_global(field.map_to_local(target_coords)) + tile_size
			player.global_position = target_pos
			direction = Direction.NONE
			player.dig(Direction.LEFT)
			destroy_selected_block(FIELD_CENTER, Direction.UP)
			destroy_selected_block(FIELD_CENTER, Direction.LEFT)
			await player.scythe_animation.animation_finished
			player.dig(Direction.RIGHT)
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
			
	enemies = enemies.filter(func(enemy):
		return is_instance_valid(enemy)
	)
	bulls = bulls.filter(func(bull):
		return is_instance_valid(bull)
	)
		
# Move player along grid tilemap grid throug tiles centers
func move_player_to_target(speed) -> void:
	if skip_intro and not is_player_intro_done:
		speed *= 15
		
	var old_player_pos = player.global_position
	
	var target_pos := coords_to_global(target_coords)
	
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
	if player.global_position.x > old_player_pos.x:
		actual_direction = Direction.RIGHT
	elif player.global_position.x < old_player_pos.x:
		actual_direction = Direction.LEFT
	elif player.global_position.y > old_player_pos.y:
		actual_direction = Direction.DOWN
	elif player.global_position.y < old_player_pos.y:
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
		player.dig(direction)
		destroy_selected_block(block_coords, cut_dir)
			
			
func destroy_selected_block(at: Vector2i, side: Direction, destroy_neighbor: bool = true) -> void:
	if side == Direction.NONE:
		return
	var block: WheatBlock = get_block_at_coords(at)
	if not is_instance_valid(block):
		return
		
	Navigation.add_nav_block(at)
	
	block.cut(side)
	if destroy_neighbor:
		var n_at := at + Vector2i(dir_to_vec(side))
		var n := get_block_at_coords(n_at)
		if is_instance_valid(n):
			Navigation.add_nav_block(n_at)
			n.cut(dir_invert(side), side)
			Navigation.add_conection(at, n_at)
			
	#if Global.draw_debug:
	queue_redraw()
	
	
func get_block_at_coords(block_coords: Vector2i) -> WheatBlock:
	
	if grid.has(block_coords):
		#print("returned from cache")
		return grid.get(block_coords)
	
	var global_pos := coords_to_global(block_coords)
	
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
	
	var block = collider.get_parent()
	grid.set(block_coords, block)
	return block
	
	
func move_enemies(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		enemy.grid_coords = global_to_coords(enemy.global_position)
			
		if enemy.is_ghost:
			enemy.global_target_pos = player.global_position
			if enemy.has_path():
				enemy.turn_normal()
		
		if enemy.global_position.distance_squared_to(enemy.global_target_pos) < 1:
			if enemy.has_path() and not Navigation.is_disabled(enemy.grid_coords):
				var target := enemy.get_target()
				var pos := coords_to_global(target)
				enemy.global_target_pos = pos
			else:
				if randf() < ghost_probability:
					enemy.turn_into_ghost()
				enemy.current_path.clear()
				var next_point := enemy.grid_coords + Vector2i(dir_to_vec(enemy.current_roam_direction))
				if Navigation.can_beeline(enemy.grid_coords, next_point):
					enemy.global_target_pos = coords_to_global(next_point)
				else:
					enemy.change_direction()
			
		enemy.global_position = enemy.global_position.move_toward(enemy.global_target_pos, enemy.current_speed * delta)
	
	
func move_bulls(delta: float) -> void:
	for bull in bulls:
		if not is_instance_valid(bull):
			continue
		bull.grid_coords = global_to_coords(bull.global_position)
		
		if not bull.is_raged:
			if Navigation.has_point(bull.grid_coords + Vector2i.DOWN):
				destroy_selected_block(bull.grid_coords, Direction.DOWN)
				bull.rage()
		if bull.is_running:
			Navigation.set_disabled(bull.grid_coords, false)
			if Navigation.can_beeline(bull.grid_coords, bull.grid_coords + Vector2i.DOWN):
				bull.global_target_pos = coords_to_global(bull.grid_coords + Vector2i.DOWN)
			elif bull.can_destroy_count > 0:
				destroy_selected_block(bull.grid_coords, Direction.DOWN)
				bull.can_destroy_count -= 1
			else:
				bull.stop()
				Navigation.set_disabled(bull.grid_coords, true)
				bull.global_position = coords_to_global(bull.grid_coords)
			bull.global_position = bull.global_position.move_toward(bull.global_target_pos, bull.speed * delta)
			
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
	
	if event.as_text() == 'F1' and event.is_pressed():
		start_level()
		
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
	
	
func _draw() -> void:
	#if not Global.draw_debug:
		#return		
	draw_set_transform(Vector2(208, 112))
	Navigation.draw(self)
