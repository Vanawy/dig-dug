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

const TILE_SIZE: float = 16


static func clear_mask_bit(mask: int, bit: int) -> int:
	return mask & ~(1 << bit)

static func set_mask_bit(mask: int, bit: int) -> int:
	return mask | (1 << bit)
