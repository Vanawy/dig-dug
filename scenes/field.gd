extends TileMapLayer
class_name Field

@export var size: Vector2i = Vector2i(11, 12)
var grid: Dictionary[Vector2i, WheatBlock] = {}

const WHEAT_IN_CELL: int = 10
const WHEAT_PARTS_OFFSETS: Array[Vector2] = [
	Vector2(14, 0 ),
	Vector2(10, 1 ),
	Vector2(8,  2 ),
	Vector2(6,  7 ),
	Vector2(14, 7 ),
	
	Vector2(2,  8 ),
	Vector2(11, 10),
	Vector2(9,  11),
	Vector2(5,  14),
	Vector2(1,  15),
]

const WHEAT_PARTS_FRAMES: Array[int] = [
	0,
	3,
	1,
	1,
	2,
	1,
	0,
	1,
	1,
	2
]
const WHEAT_FRAMES: float = 5
const FRAME_SIZE: float = 1.0 / WHEAT_FRAMES


func _ready() -> void:
	var multimesh2d := $MultiMeshInstance2D as MultiMeshInstance2D
	multimesh2d.multimesh.instance_count = size.x * size.y * WHEAT_IN_CELL
	
	for i in size.x:
		for j in size.y:
			for k in WHEAT_IN_CELL:
				var index := i * size.y * WHEAT_IN_CELL + j * WHEAT_IN_CELL + k
				#print(i, j, " ", index)
				var angle = PI
				var pos = Vector2(i, j) * Global.TILE_SIZE + WHEAT_PARTS_OFFSETS[k]
				 #+ Vector2(0, -6)
				multimesh2d.multimesh.set_instance_transform_2d(index, Transform2D(angle, pos))
				multimesh2d.multimesh.set_instance_custom_data(index, 
				Color(
					WHEAT_PARTS_FRAMES[k] * FRAME_SIZE, # UV offset
					randf(), # Wind time offset
					0, # unused
					1 # visibility
				))
				
		

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
	
	var block := collider.get_parent() as WheatBlock
	block.remove_hitbox()
	grid.set(block_coords, block)
	return block
	
