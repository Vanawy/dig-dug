extends Node
enum Direction {NONE, UP, DOWN, LEFT, RIGHT}

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

static func clear_mask_bit(mask: int, bit: int) -> int:
	return mask & ~(1 << bit)

static func set_mask_bit(mask: int, bit: int) -> int:
	return mask | (1 << bit)


@onready var _sfx_bus = AudioServer.get_bus_index("SFX")
@onready var _bg_bus = AudioServer.get_bus_index("Background")
@onready var _music_bus = AudioServer.get_bus_index("Music")

var sfx_volume: float = 1.0:
	set(v):
		sfx_volume = v
		print("volume " + str(v))
		AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(v))
var bg_volume: float = 1.0:
	set(v):
		bg_volume = v
		print("volume " + str(v))
		AudioServer.set_bus_volume_db(_bg_bus, linear_to_db(v))
var music_volume: float = 1.0:
	set(v):
		music_volume = v
		print("volume " + str(v))
		AudioServer.set_bus_volume_db(_music_bus, linear_to_db(v))

func _ready() -> void:
	sfx_volume = 1
	bg_volume = 1
	music_volume = 1
	
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
