@tool
class_name ColorSource
extends Node2D

const SIZE = 256
const FEATHER = 1.6

@export var power: float = 0.1

@export var visibility_box: VisibleOnScreenEnabler2D

func _ready() -> void:
	Global.draw_debug_toggled.connect(queue_redraw)

func _process(_delta: float) -> void:
	gizmo()
	var size: float = SIZE * power;
	if is_instance_valid(visibility_box):
		visibility_box.rect = Rect2(-size, -size, size * 2, size * 2)

	
func gizmo() -> void:
	if not Engine.is_editor_hint() and not Global.draw_debug:
		return
	queue_redraw()
		
func _draw() -> void:
	if not Engine.is_editor_hint() and not Global.draw_debug:
		return
	draw_circle(Vector2.ZERO, SIZE * power, Color.AQUA, false, 1.0, false)
	draw_circle(Vector2.ZERO, SIZE * power * FEATHER, Color.AQUAMARINE, false, 1.0, false)
	
func get_power() -> float:
	return power if visible else 0.0
