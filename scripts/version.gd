@tool
extends Label

const VERSION_FILE: String = "res://version.txt"
const SETTING_PATH: String = "application/config/version"

@export_tool_button("patch++")
var patch = _increment_patch
@export_tool_button("minor++")
var minor = _increment_minor
@export_tool_button("Update file")
var update_file = _update_file


@export var version: String = "0.0.0"
@export_tool_button("Set")
var set_v = _set_version
@export_tool_button("Get")
var get_v = _get_version


func get_current_version() -> String:
	return ProjectSettings.get_setting(SETTING_PATH)

func _ready() -> void:
	_get_version()

func _increment_minor() -> void:
	_increment(true)
	
func _increment_patch() -> void:
	_increment(false)
	
func _increment(is_minor: bool) -> void:
	var v_str := get_current_version()
	var parts := v_str.split(".")
	
	var i := 2
	if is_minor:
		i = 1
		
	parts[i] = str(int(parts[i]) + 1)
	
	ProjectSettings.set_setting(SETTING_PATH, ".".join(parts))
	_update_file()
	
func _set_version() -> void:
	ProjectSettings.set_setting(SETTING_PATH, version)
	_update_file()
	
func _get_version() -> void:
	version = get_current_version()
	text = "v" + version

func _update_file() -> void:
	var file = FileAccess.open(VERSION_FILE, FileAccess.WRITE)
	file.store_string(get_current_version())
	file.close()
	_get_version()
	print(get_current_version())
