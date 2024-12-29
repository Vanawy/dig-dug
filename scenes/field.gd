extends TileMapLayer
class_name Field

var grid: Dictionary[Vector2i, WheatBlock] = {}

func destroy_selected_block(at: Vector2i, side: Game.Direction, destroy_neighbor: bool = true) -> void:
	if side == Game.Direction.NONE:
		return
	var block: WheatBlock = get_block_at_coords(at)
	if not is_instance_valid(block):
		return
		
	Navigation.add_nav_block(at)
	
	block.cut(side)
	if destroy_neighbor:
		var n_at := at + Vector2i(Game.dir_to_vec(side))
		var n := get_block_at_coords(n_at)
		if is_instance_valid(n):
			Navigation.add_nav_block(n_at)
			n.cut(Game.dir_invert(side), side)
			Navigation.add_conection(at, n_at)
			
	#if Global.draw_debug:
	queue_redraw()
	
	
func global_to_coords(pos: Vector2) -> Vector2i:
	return local_to_map(to_local(pos))
	
func coords_to_global(coords: Vector2i) -> Vector2:
	return to_global(map_to_local(coords))
	
func get_block_at_coords(block_coords: Vector2i) -> WheatBlock:
	
	if grid.has(block_coords):
		#print("returned from cache")
		return grid.get(block_coords)
	
	var global_pos := coords_to_global(block_coords)
	
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(global_pos, global_pos + Vector2.DOWN, (1 << Global.Layers.WHEAT))
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
	
