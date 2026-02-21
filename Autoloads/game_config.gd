class_name GameConfig
extends Node

signal config_changed(path, value)

# Animation & visual constants
const MOVEMENT_TWEEN_DURATION := 0.2
const MOVEMENT_TWEEN_TRANS := Tween.TRANS_SINE
const MOVEMENT_TWEEN_EASE := Tween.EASE_OUT

# Grid & hex constants
const DEFAULT_HEX_SIZE := Vector2i(64, 64)
const DEFAULT_GRID_WIDTH := 7
const DEFAULT_GRID_HEIGHT := 7

# Scene paths
const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

const DEFAULT_CONFIG := {
	"audio": {
		"master_db": 0.0,
		"music_db": -3.0,
		"sfx_db": -3.0,
	},
	"controls": {
		"invert_y": false,
	},
	"gameplay": {
		"difficulty": "normal",
		"animation_speed": "normal",
	},
	"display": {
		"orientation": "landscape",
		"resolution": Vector2i(1920, 1080),
	},
	"dialogue": {
		"auto_advance_enabled": false,
		"auto_advance_speed": 1.0,
		"text_speed": 1.0,
	}
}

@export var config_path := "user://hex_config.cfg"
var _config: Dictionary = {}

func _ready() -> void:
	reset_to_defaults()
	load_config()

func reset_to_defaults() -> void:
	_config = DEFAULT_CONFIG.duplicate(true)

func set_value(path: String, value) -> void:
	_set_by_path(path, value)
	emit_signal("config_changed", path, value)

func get_value(path: String, default_value = null):
	return _get_by_path(path, default_value)

func save_config() -> void:
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_var(_config, true)
		file.close()

func load_config() -> void:
	if not FileAccess.file_exists(config_path):
		return
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file:
		var data = file.get_var(true)
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			_config = _deep_merge(DEFAULT_CONFIG.duplicate(true), data)

func _set_by_path(path: String, value) -> void:
	var keys := path.split("/")
	var current = _config
	for i in range(keys.size() - 1):
		var key := keys[i]
		if not current.has(key) or typeof(current[key]) != TYPE_DICTIONARY:
			current[key] = {}
		current = current[key]
	var leaf := keys[keys.size() - 1]
	current[leaf] = value

func _get_by_path(path: String, default_value):
	var keys := path.split("/")
	var current = _config
	for key in keys:
		if typeof(current) != TYPE_DICTIONARY or not current.has(key):
			return default_value
		current = current[key]
	return current

func _deep_merge(base: Dictionary, update: Dictionary) -> Dictionary:
	for key in update.keys():
		var value = update[key]
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
			base[key] = _deep_merge(base[key], value)
		else:
			base[key] = value
	return base
