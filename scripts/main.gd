extends Node2D


@export var pause_ui: PauseUI

@onready var tree: SceneTree = get_tree()

func _ready() -> void:
	pause_ui.continue_pressed.connect(unpause)
	return
	
	
func pause_toggle() -> void:
	if get_tree().paused:
		unpause()
	else:
		pause()
	
func pause() -> void:
	if tree.paused:
		return
	tree.paused = true
	pause_ui.pause()
	
func unpause() -> void:
	if not tree.paused:
		return
	pause_ui.unpause()
	await pause_ui.visibility_changed
	tree.paused = false
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		pause_toggle()
