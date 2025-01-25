@tool
extends Label

const VERSION_FILE: String = "res://version.txt"
const SETTING_PATH: String = "application/config/version"

@export var version_text: String = "v"

@export_tool_button("minor *.+.0")
var minor: Callable = _increment_minor
@export_tool_button("patch *.*.+")
var patch: Callable = _increment_patch
@export_tool_button("Update file")
var update_file: Callable = _update_file


@export var version: String = "0.0.0"
@export_tool_button("Set")
var set_v: Callable = _set_version
@export_tool_button("Get")
var get_v: Callable = _get_version


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
	
	if is_minor:
		parts[1] = str(int(parts[1]) + 1)
		parts[2] = str(0)
	else:
		parts[2] = str(int(parts[2]) + 1)
	
	ProjectSettings.set_setting(SETTING_PATH, ".".join(parts))
	_update_file()
	
func _set_version() -> void:
	ProjectSettings.set_setting(SETTING_PATH, version)
	_update_file()
	
func _get_version() -> void:
	version = get_current_version()
	text = version_text + version

func _update_file() -> void:
	var file = FileAccess.open(VERSION_FILE, FileAccess.WRITE)
	file.store_string(get_current_version())
	file.close()
	_get_version()
	print(get_current_version())
