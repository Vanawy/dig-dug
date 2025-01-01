extends TileMapLayer
class_name Field

@export var size: Vector2i = Vector2i(11, 12)
var grid: Dictionary[Vector2i, WheatBlock] = {}

const WHEAT_IN_CELL: int = 10

const WHEAT_PARTS_DATA: Array[Array] = [
	# x, y, frame_n
	[14, 0 , 0],
	[10, 1 , 3],
	[8,  2 , 1],
	[6,  7 , 1],
	[14, 7 , 2],
	
	[2,  8 , 1],
	[11, 10, 0],
	[9,  11, 1],
	[5,  14, 1],
	[1,  15, 2],
]
const PARTS_REMOVE: Dictionary[Game.Direction, Array] = {
	Game.Direction.NONE: [3,6,7],
	Game.Direction.UP: [1,2],
	Game.Direction.LEFT: [5],
	Game.Direction.RIGHT: [4],
	Game.Direction.DOWN: [8]
}

const WHEAT_FRAMES: float = 5
const FRAME_SIZE: float = 1.0 / WHEAT_FRAMES

@export_category("Nodes")
@export var multimesh2d: MultiMeshInstance2D

func _ready() -> void:
	multimesh2d.multimesh.instance_count = size.x * size.y * WHEAT_IN_CELL
	
	for i in size.x:
		for j in size.y:
			for k in WHEAT_IN_CELL:
				var index := i * size.y * WHEAT_IN_CELL + j * WHEAT_IN_CELL + k
				#print(i, j, " ", index)
				var angle = PI
				var pos = Vector2(i, j) * Global.TILE_SIZE + Vector2(WHEAT_PARTS_DATA[k][0], WHEAT_PARTS_DATA[k][1])
				 #+ Vector2(0, -6)
				multimesh2d.multimesh.set_instance_transform_2d(index, Transform2D(angle, pos))
				multimesh2d.multimesh.set_instance_custom_data(index, 
				Color(
					WHEAT_PARTS_DATA[k][2] * FRAME_SIZE, # UV offset
					randf(), # Wind time offset
					0, # unused
					1 # visibility
				))
				
	return

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
	return
	
	
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
	
	var block := collider.get_parent() as WheatBlock
	block.remove_hitbox()
	grid.set(block_coords, block)
	block.grid_coords = block_coords
	block.on_side_cut.connect(cut_block)
	block.on_reset.connect(reset_block)
	
	return block
	
	
	
func cut_block(at: Vector2i, dir: Game.Direction) -> void:
	for k: int in PARTS_REMOVE[dir]:
		var index := at.x * size.y * WHEAT_IN_CELL + at.y * WHEAT_IN_CELL + k
		var data := multimesh2d.multimesh.get_instance_custom_data(index)
		data.a = 0
		multimesh2d.multimesh.set_instance_custom_data(index, data)
	return
	
func reset_block(at: Vector2i) -> void:
	for k in WHEAT_IN_CELL:
		var index := at.x * size.y * WHEAT_IN_CELL + at.y * WHEAT_IN_CELL + k
		var data := multimesh2d.multimesh.get_instance_custom_data(index)
		data.a = 1
		multimesh2d.multimesh.set_instance_custom_data(index, data)
	return
