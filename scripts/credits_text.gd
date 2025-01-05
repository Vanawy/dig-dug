extends RicherTextLabel


func _ready() -> void:
	var file := FileAccess.open("res://CREDITS.txt", FileAccess.READ)
	text = file.get_as_text()
