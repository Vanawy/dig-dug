extends Node

signal draw_debug_toggled(v: bool)

var draw_debug: bool = true:
	set(v):
		draw_debug = v
		draw_debug_toggled.emit(v)
