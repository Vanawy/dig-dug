extends Control
class_name GameUI

@export var player_hp_progress: TextureProgressBar
@export var level_label: Label
@export var score_label: Label

var player_hp: int = 0:
	set(v):
		player_hp_progress.value = v

var level: int = 0:
	set(v):
		level_label.text = str(v).pad_zeros(2)

var score: int = 0:
	set(v):
		score_label.text = str(v).pad_zeros(7)
