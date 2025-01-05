extends Resource
class_name GameSettings

signal on_update

@export var sfx_on: bool = true:
	set(v):
		sfx_on = v
		on_update.emit()
@export var bg_on: bool = true:
	set(v):
		bg_on = v
		on_update.emit()
@export var music_on: bool = true:
	set(v):
		music_on = v
		on_update.emit()

func _to_string() -> String:
	return "sfx: " + str(sfx_on) + "; bg: " + str(bg_on) + "; music: " + str(music_on);
