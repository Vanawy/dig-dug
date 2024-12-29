@tool

extends Node2D
class_name SpawnPoint

enum Type {
	ROCK,
	HORIZONTAL,
	VERTICAL,
	ANY
}

enum Size {
	SMALL = 3,
	BIG = 5,
}

@export var type: Type = Type.ANY

@export var size: Size = Size.BIG

func _ready() -> void:
	if not Engine.is_editor_hint():
		Global.draw_debug_toggled.connect(func(v: bool):
			queue_redraw()
		)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	

func _draw() -> void:
	if Engine.is_editor_hint() or Global.draw_debug:
		if type == Type.HORIZONTAL or type == Type.ANY:
			var width: float = Global.TILE_SIZE.x * size
			draw_rect(Rect2(-width / 2, -Global.TILE_SIZE.x / 2, width, Global.TILE_SIZE.y), Color.AQUA, false, 1.0)
		if type == Type.VERTICAL or type == Type.ANY:
			var height: float = Global.TILE_SIZE.y * size
			draw_rect(Rect2(-Global.TILE_SIZE.x / 2, -height / 2, Global.TILE_SIZE.x, height), Color.DARK_CYAN, false, 1.0)
		if type == Type.ROCK:
			draw_rect(Rect2(-Global.TILE_SIZE.x / 2, -Global.TILE_SIZE.y / 2, Global.TILE_SIZE.x, Global.TILE_SIZE.y), Color.INDIAN_RED, false, 1.0)
		
