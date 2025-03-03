extends Node
enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

const PB_FILE: String = "user://pb.dat"
const SETTINGS_FILE: String = "user://settings.tres"


signal draw_debug_toggled(v: bool)

var draw_debug: bool = false:
	set(v):
		draw_debug = v
		draw_debug_toggled.emit(v)

enum Layers {
	WALLS = 0,
	ENEMIES = 1,
	BULLS = 2,
	PLAYER = 3,
	WHEAT = 7,
}

const TILE_SIZE: Vector2 = Vector2(16, 16)

var rng: RandomNumberGenerator


var best_score: int = 0

static func clear_mask_bit(mask: int, bit: int) -> int:
	return mask & ~(1 << bit)

static func set_mask_bit(mask: int, bit: int) -> int:
	return mask | (1 << bit)


@onready var _sfx_bus = AudioServer.get_bus_index("SFX")
@onready var _bg_bus = AudioServer.get_bus_index("Background")
@onready var _music_bus = AudioServer.get_bus_index("Music")


var settings: GameSettings

func _ready() -> void:
	load_settings()
	settings.on_update.connect(func(): 
		AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(int(settings.sfx_on)))
		AudioServer.set_bus_volume_db(_bg_bus, linear_to_db(int(settings.bg_on)))
		AudioServer.set_bus_volume_db(_music_bus, linear_to_db(int(settings.music_on)))
		save_settings()
	)
	settings.on_update.emit()
	load_pb()
	reset_rng()
	
func reset_rng() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = hash("Godot")
	print(rng.randf())
	
func seeded_shuffle(array: Array) -> Array:
	var temp = []
	while array.size() > 0:
		temp.append(array.pop_at(Global.rng.randi_range(0, array.size() - 1)))
	return temp
	
func load_settings() -> void:
	settings = preload("res://default_game_settings.tres") as GameSettings
	if ResourceLoader.exists(SETTINGS_FILE):
		settings = ResourceLoader.load(SETTINGS_FILE, type_string(typeof(settings)))
		print("settings loaded")
	print(str(settings))
	return
	
func save_settings() -> void:
	var res := ResourceSaver.save(settings, SETTINGS_FILE)
	if res == OK:
		print("saved: " + str(settings))
	else:
		print("cant save settings: " + str(res))
	
func update_best_score(new_best: int) -> void:
	if new_best > best_score:
		best_score = new_best
		save_pb()
		
func save_pb():
	var file = FileAccess.open(PB_FILE, FileAccess.WRITE)
	file.store_string(str(best_score))
	file.close()
	
func load_pb():
	var file = FileAccess.open(PB_FILE, FileAccess.READ)
	if !file:
		return
	var content = file.get_as_text()
	file.close()
	best_score = int(content)
	print("pb: " + str(best_score))
	
