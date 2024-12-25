extends Control
class_name GameUI

@export var player_hp_progress: TextureProgressBar

var player_hp: int = 0:
	set(v):
		player_hp = v
		player_hp_progress.value = player_hp
