extends HBoxContainer
class_name SoundUI

@export_category("Nodes")
@export var sfx: CheckBox
@export var bg: CheckBox
@export var music: CheckBox

func _ready() -> void:
	
	sfx.button_pressed = (Global.sfx_volume > 0)
	bg.button_pressed = (Global.bg_volume > 0)
	music.button_pressed = (Global.music_volume > 0)
	
	sfx.toggled.connect(func(v: bool):
		Global.sfx_volume = 1 if v else 0
	)
	bg.toggled.connect(func(v: bool):
		Global.bg_volume = 1 if v else 0
	)
	music.toggled.connect(func(v: bool):
		Global.music_volume = 1 if v else 0
	)
