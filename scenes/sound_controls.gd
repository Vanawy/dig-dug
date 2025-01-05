extends HBoxContainer
class_name SoundUI

@export_category("Nodes")
@export var sfx: CheckBox
@export var bg: CheckBox
@export var music: CheckBox

func _ready() -> void:
	
	sfx.button_pressed = Global.settings.sfx_on
	bg.button_pressed = Global.settings.bg_on
	music.button_pressed = Global.settings.music_on
	
	sfx.toggled.connect(func(v: bool):
		Global.settings.sfx_on = v
	)
	bg.toggled.connect(func(v: bool):
		Global.settings.bg_on = v
	)
	music.toggled.connect(func(v: bool):
		Global.settings.music_on = v
	)
