extends CanvasItem

const SOURCES_LIMIT: int = 256;

@export var sources: Array[ColorSource]

var sources_image: Image

func _ready() -> void:
	visible = true
	
	sources_image = Image.create_empty(SOURCES_LIMIT, 1, false, Image.FORMAT_RGB8)
	update_sources()
	update_shader_params()
	
	
func _physics_process(delta: float) -> void:
	update_sources()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_shader_params()
	
func update_shader_params() -> void:
	sources_image.fill(Color.BLACK)
	for i in min(len(sources), SOURCES_LIMIT):
		var source := sources[i]
		if not is_instance_valid(source):
			continue
		var uv_pos = source.get_global_transform_with_canvas().origin / get_viewport_rect().size
		sources_image.set_pixelv(Vector2(i, 0), Color(uv_pos.x, uv_pos.y, source.get_power(), 1.0))
	#print(sources)
	material.set("shader_parameter/sources", ImageTexture.create_from_image(sources_image))
	
	
func update_sources() -> void:
	sources = []
	# FIXME: Ignore offscreen sources
	for source: ColorSource in get_tree().get_nodes_in_group("color_source"):
		if not source is ColorSource:
			continue
		if source.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		sources.push_back(source)
	
