extends Node2D


@export var pause_ui: PauseUI
@export var game_over_ui: GameOverUI
@export var game: Game

@onready var tree: SceneTree = get_tree()

func _ready() -> void:
	pause_ui.continue_button.pressed.connect(unpause)
	pause_ui.restart_button.pressed.connect(restart)
	game_over_ui.restart_button.pressed.connect(restart)
	
	game.on_game_over.connect(game_over)
	
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
	
func restart() -> void:
	pause_ui.unpause()
	await pause_ui.visibility_changed
	tree.paused = false
	game.restart_game()
	
func game_over(score: int, pb: int) -> void:
	tree.paused = true
	game_over_ui.game_over(score, pb)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		pause_toggle()
