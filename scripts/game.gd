extends Node2D
class_name Game

enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

const FIELD_CENTER: Vector2i = Vector2i(5,6)
const PLAYER_SPAWN: Vector2i = Vector2i(5, -1)

const DIG_OFFSET: float = 4

const MAX_HP: int = 3

@export var skip_intro: bool = true

var player_health: int = 0:
	set(v):
		player_health = v
		game_ui.player_hp = player_health
		
var level: int = 1:
	set(v):
		level = v
		game_ui.level += level
		
var score: int = 0:
	set(v):
		score = v
		game_ui.score += score
		#if score > global.high_score:
			#global.high_score

@export_category("Spawn Points")
var bull_spawns: Array[SpawnPoint] = []
var enemy_spawns: Array[SpawnPoint] = []

@export_category("Children")
@export var field: Field
@export var player: Player
@export var game_camera: GameCamera
@export var game_ui: GameUI

var is_game_started: bool = false
var is_player_intro_done: bool = false
var target_coords: Vector2i = Vector2.ZERO

var bulls_amount: int = 3
var enemies_amount: int = 3

var enemies_additional_speed: float = 0
var enemies_additional_speed_increase: float = 2

@export var ghost_probability: float = 0.03

var enemies: Array[Enemy] = []
var bulls: Array[Bull] = []


signal on_game_over(score: int, pb: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level = 1
	score = 0
	start_level()
	player_health = MAX_HP
		
	var spawns = get_tree().get_nodes_in_group("spawn") as Array[SpawnPoint]
	for spawn in spawns:
		if spawn.type == SpawnPoint.Type.ROCK:
			bull_spawns.push_back(spawn)
		else:
			enemy_spawns.push_back(spawn)
			
	player.on_death.connect(func(): 
		player_health -= 1
		if player_health <= 0:
			game_over()
		respawn_player()
	)
			
func start_level() -> void:
	# remove old enemies
	for node in enemies + bulls:
		node.queue_free()
		
	for i in field.size.x + 1:
		for j in field.size.y + 1:
			var block := field.get_block_at_coords(Vector2i(i, j))
			if is_instance_valid(block):
				block.reset_sides()
	get_tree().call_group("wheat_part", "reset")
	
	Navigation.field_size = field.size
	Navigation.navigation.clear()
	Navigation.visualisation_paths.clear()
	spawn_enemies.call_deferred()
	
	respawn_player()
	if level != 1 or skip_intro:
		game_camera.position = Vector2.ZERO
		game_camera.move_camera()

func respawn_player() -> void:
	player.respawn()
	if is_game_started:
		player.global_position = field.coords_to_global(PLAYER_SPAWN)
		is_player_intro_done = false
	target_coords = FIELD_CENTER
		
	for enemy in enemies:
		enemy.respawn()

func spawn_enemies() -> void:
	var spawns := Global.seeded_shuffle(bull_spawns.duplicate())
	for i in bulls_amount:
		var spawn := spawns.pop_back() as SpawnPoint
		var coords = field.global_to_coords(spawn.global_position)
		field.destroy_selected_block(coords, Direction.DOWN, false)
		Navigation.set_disabled(coords, true)
		var bull = preload("res://scenes/bull.tscn").instantiate()
		bull.global_position = spawn.global_position
		player.add_sibling(bull) 
		bulls.append(bull)
		
	spawns = Global.seeded_shuffle(enemy_spawns.duplicate())
	for i in enemies_amount:
		var spawn := spawns.pop_back() as SpawnPoint
		var coords = field.global_to_coords(spawn.global_position)
		var type := spawn.type
		if type == SpawnPoint.Type.ANY:
			type = [SpawnPoint.Type.HORIZONTAL, SpawnPoint.Type.VERTICAL][Global.rng.randi_range(0, 1)]
			
		var offset: int = floor(Global.rng.randf() * spawn.size) - ceil(spawn.size / 2)
		var pos_offset: Vector2 = Vector2.ZERO
		if type == SpawnPoint.Type.HORIZONTAL:
			pos_offset.x = offset
			field.destroy_selected_block(coords, Direction.LEFT)
			field.destroy_selected_block(coords, Direction.RIGHT)
			if spawn.size == SpawnPoint.Size.BIG:
				field.destroy_selected_block(coords + Vector2i.LEFT, Direction.LEFT)
				field.destroy_selected_block(coords + Vector2i.RIGHT, Direction.RIGHT)
		if type == SpawnPoint.Type.VERTICAL:
			pos_offset.y = offset
			field.destroy_selected_block(coords, Direction.UP)
			field.destroy_selected_block(coords, Direction.DOWN)
			if spawn.size == SpawnPoint.Size.BIG:
				field.destroy_selected_block(coords + Vector2i.UP, Direction.UP)
				field.destroy_selected_block(coords + Vector2i.DOWN, Direction.DOWN)
		var enemy: Enemy
		if i % 3 == 0:
			enemy = preload("res://scenes/enemy_priest.tscn").instantiate()
		else:
			enemy = preload("res://scenes/enemy.tscn").instantiate()
			
		enemy.global_position = spawn.global_position + pos_offset * Global.TILE_SIZE
		enemy.global_spawn_pos = enemy.global_position
		enemy.speed += enemies_additional_speed
		player.add_sibling(enemy) 
		enemies.append(enemy)
		enemy.on_death.connect(func():
			score += 500
		)
		
func game_over() -> void:
	print("game over")
	Global.update_best_score(score)
	on_game_over.emit(score, Global.best_score)
	
func restart_game() -> void:
	Global.reset_rng()
	get_tree().reload_current_scene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	pass


func _physics_process(delta: float) -> void:
	
	for at_grid: GridCoordinates in get_tree().get_nodes_in_group("on_grid"):
		at_grid.at = field.global_to_coords(at_grid.global_position)
	
	#print(Navigation.player_pos_id)
		
	if is_player_intro_done:
		move_enemies(delta)
		move_bulls(delta)
		
		
	# INTRO DONE code
	if not is_player_intro_done:
		var target_pos := field.coords_to_global(target_coords)
		#direction = Direction.DOWN
		if player.global_position.distance_squared_to(target_pos) < 1:
			is_player_intro_done = true
			is_game_started = true
			#direction = Direction.NONE
			player.dig(Direction.LEFT)
			field.destroy_selected_block(FIELD_CENTER, Direction.UP)
			field.destroy_selected_block(FIELD_CENTER, Direction.LEFT)
			await player.scythe_animation.animation_finished
			player.dig(Direction.RIGHT)
			field.destroy_selected_block(FIELD_CENTER, Direction.RIGHT)
	
	move_player_to_target(player.speed * delta)
	destroy_current_block(player.grid_coords.at)
			
	enemies = enemies.filter(func(enemy):
		return is_instance_valid(enemy)
	)
	bulls = bulls.filter(func(bull):
		return is_instance_valid(bull)
	)
	
	if is_player_intro_done and enemies.is_empty() and not player.is_dead:
		next_level()
		
func next_level() -> void:
	level += 1
	score += 1000
	if level % 3 == 0:
		enemies_amount += 1
	enemies_additional_speed += enemies_additional_speed_increase
	skip_intro = false
	start_level()
	
		
# Move player along grid tilemap grid throug tiles centers
func move_player_to_target(speed) -> void:		
	var old_player_pos = player.global_position
	
	var target_pos := field.coords_to_global(player.get_target())
	var dir := player.in_direction
	
	
	if not is_player_intro_done:
		target_pos = field.coords_to_global(target_coords)
		dir = Direction.DOWN
		if skip_intro:
			speed *= 15
	
	#print("target: " + str(target_pos) + " pl: " + str(old_player_pos))
	match dir:
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
	
	player.update_sprites(actual_direction)
		
func destroy_current_block(block_coords: Vector2i) -> void:
	var block: WheatBlock = field.get_block_at_coords(block_coords)
	if not is_instance_valid(block):
		return
	var pos_dif = block.to_local(player.global_position) - (Global.TILE_SIZE / 2)
	
	var cut_dir := Direction.NONE
	
	match player.move_direction:
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
		player.dig(player.move_direction)
		field.destroy_selected_block(block_coords, cut_dir)
		if is_player_intro_done and not player.is_dead:
			score += 10
			
			
	
func move_enemies(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		if enemy.is_dead:
			continue
			
		if enemy.is_ghost:
			enemy.global_target_pos = player.global_position
			if enemy.has_path():
				enemy.turn_normal()
		
		if enemy.global_position.distance_squared_to(enemy.global_target_pos) < 1:
			if enemy.has_path() and not Navigation.is_disabled(enemy.grid_coords.at):
				var target := enemy.get_target()
				var pos := field.coords_to_global(target)
				enemy.global_target_pos = pos
			else:
				if Global.rng.randf() < ghost_probability:
					enemy.turn_into_ghost()
				enemy.current_path.clear()
				var next_point := enemy.grid_coords.at + Vector2i(dir_to_vec(enemy.current_roam_direction))
				if Navigation.can_beeline(enemy.grid_coords.at, next_point):
					enemy.global_target_pos = field.coords_to_global(next_point)
				else:
					enemy.change_direction()
			
		enemy.global_position = enemy.global_position.move_toward(enemy.global_target_pos, enemy.current_speed * delta)
	
	
func move_bulls(delta: float) -> void:
	for bull in bulls:
		if not is_instance_valid(bull):
			continue
		
		var at = bull.grid_coords.at
		
		if not bull.is_raged:
			if Navigation.has_point(at + Vector2i.DOWN):
				field.destroy_selected_block(at, Direction.DOWN)
				bull.rage()
		if bull.is_running:
			Navigation.set_disabled(at, false)
			if Navigation.can_beeline(at, at + Vector2i.DOWN):
				bull.global_target_pos = field.coords_to_global(at + Vector2i.DOWN)
			elif bull.can_destroy_count > 0:
				field.destroy_selected_block(at, Direction.DOWN)
				bull.can_destroy_count -= 1
			else:
				bull.stop()
				Navigation.set_disabled(at, true)
				bull.global_position = field.coords_to_global(at)
			bull.global_position = bull.global_position.move_toward(bull.global_target_pos, bull.speed * delta)
			
func _unhandled_input(event: InputEvent) -> void:
				
	if not is_player_intro_done:
		if event.is_action_pressed("player_attack"):
			skip_intro = true
			game_camera.position = Vector2.ZERO
			game_camera.move_camera()
		
	
	if event.as_text() == 'F1' and event.is_pressed():
		next_level()
		
	if event.as_text() == 'F2' and event.is_pressed():
		game_over()
		
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

static func vec_to_dir(vector: Vector2, priority: Direction = Direction.NONE) -> Direction:
	if vector.is_zero_approx():
		return Direction.NONE
	var ax: float = abs(vector.x)
	var ay: float = abs(vector.y)
	if abs(ax - ay) < 0.05:
		return priority
	
	if abs(ax) > abs(ay):
		if vector.x > 0:
			return Direction.RIGHT
		else:
			return Direction.LEFT
	else:
		if vector.y > 0:
			return Direction.DOWN
		else:
			return Direction.UP
	
func _draw() -> void:
	#if not Global.draw_debug:
		#return		
		
	#draw_circle(to_local(field.coords_to_global(player.grid_coords.at)), 2, Color.GREEN, true)
	#draw_circle(to_local(field.coords_to_global(player.get_target())), 2, Color.RED, true)
	#draw_set_transform(Vector2(206, 112))
	#Navigation.draw(self)
	pass
