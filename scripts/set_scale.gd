extends CanvasLayer

@export var target_scale: Vector2 = Vector2(3, 3)

func _ready() -> void:
	scale = target_scale
	
