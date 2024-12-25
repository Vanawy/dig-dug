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
			var width: float = Global.TILE_SIZE * size
			draw_rect(Rect2(-width / 2, -Global.TILE_SIZE / 2, width, Global.TILE_SIZE), Color.AQUA, false, 1.0)
		if type == Type.VERTICAL or type == Type.ANY:
			var height: float = Global.TILE_SIZE * size
			draw_rect(Rect2(-Global.TILE_SIZE / 2, -height / 2, Global.TILE_SIZE, height), Color.DARK_CYAN, false, 1.0)
		if type == Type.ROCK:
			var height: float = Global.TILE_SIZE * size
			draw_rect(Rect2(-Global.TILE_SIZE / 2, -Global.TILE_SIZE / 2, Global.TILE_SIZE, Global.TILE_SIZE), Color.INDIAN_RED, false, 1.0)
		
