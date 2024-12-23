extends Node


var field_size: Vector2i = Vector2i(1, 1)
var player_pos_id: int = 0

var navigation: AStar2D = AStar2D.new()

var visualisation_paths: Dictionary[RID, Array] = {}

func add_nav_block(at: Vector2i) -> void:
	if not navigation.has_point(nav_id(at)):
		navigation.add_point(nav_id(at), at, 1.0)
		
func add_conection(from: Vector2i, to: Vector2i) -> void:
	navigation.connect_points(nav_id(from), nav_id(to), true)
	
func nav_id(at: Vector2i) -> int:
	return at.x + at.y * field_size.x

func set_disabled(at: Vector2i, state: bool) -> void:
	navigation.set_point_disabled(nav_id(at), state)

func can_beeline(from: Vector2i, to: Vector2i) -> bool:
	return navigation.are_points_connected(nav_id(from), nav_id(to))

func draw(item: CanvasItem) -> void:
	
	var size := Vector2(4, 4)
		
	var off := Vector2(size.x / 2, -size.y / 2)
	for id in navigation.get_point_ids():
		var pos := navigation.get_point_position(id) * size + off
		var color := Color.PURPLE
		if navigation.is_point_disabled(id):
			color = Color.RED
			
		for con in navigation.get_point_connections(id):
			var pos_b := navigation.get_point_position(con) * size + off
			item.draw_line(pos, pos_b, Color.PLUM, 1)
			
		item.draw_circle(pos, 1, color, true)
	
	for path in visualisation_paths.values():
		var prev_pos := Vector2.ZERO
		for coords in path:
			var pos: Vector2 = Vector2(coords) * size + off
			if prev_pos != Vector2.ZERO:
				item.draw_line(pos, prev_pos, Color.RED, 1)
			prev_pos = pos
		
func update_player_pos(at: Vector2i) -> void:
	player_pos_id = nav_id(at)

func get_path_to_player(from: Vector2i) -> Array[Vector2i]:
	var from_id := nav_id(from)
	var to_id := player_pos_id
	if not navigation.has_point(from_id) or not navigation.has_point(to_id):
		return []
	
	var points := navigation.get_id_path(from_id, to_id)
	
	var coords: Array[Vector2i] = []
	
	for point in points:
		coords.append(Vector2i(navigation.get_point_position(point)))
	
	return coords
