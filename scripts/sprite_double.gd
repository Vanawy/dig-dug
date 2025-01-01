extends Sprite2D

@export var from: AnimatedSprite2D
@export var to: AnimatedSprite2D

func _ready() -> void:
	
	from.animation_changed.connect(func():
		to.play(from.animation)
		to.set_frame_and_progress(from.frame, from.frame_progress)
		return
	)
	
func _process(_delta: float) -> void:
	to.flip_h = from.flip_h
