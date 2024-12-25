extends CanvasLayer

@export var camera: Camera2D

func _ready() -> void:
	scale = camera.zoom
