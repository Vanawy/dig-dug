@tool extends RichTextEffect
class_name RichTextPB

# Syntax: [pb freq=5.0 amp=10.0][/ghost]

# Define the tag name.
var bbcode = "pb"

func _process_custom_fx(char_fx):
	# Get parameters, or use the provided default value if missing.
	var speed = char_fx.env.get("freq", 10.0)
	var amp = char_fx.env.get("amp", 10.0)

	var f = sin(char_fx.elapsed_time * speed)
	char_fx.offset.y = f * amp + (f * char_fx.relative_index )
	return true
