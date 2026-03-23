#class_name GameConfig
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

# Setting Paths
class Paths:
	const AUDIO_MASTER := GameConstants.Settings.AUDIO_MASTER
	const AUDIO_MUSIC := GameConstants.Settings.AUDIO_MUSIC
	const AUDIO_SFX := GameConstants.Settings.AUDIO_SFX
	const AUDIO_UI := GameConstants.Settings.AUDIO_UI
	const AUDIO_ENVIRONMENT := GameConstants.Settings.AUDIO_ENVIRONMENT
	const AUDIO_NARRATIVE := GameConstants.Settings.AUDIO_NARRATIVE

	const AUDIO_MASTER_MUTED := GameConstants.Settings.AUDIO_MASTER_MUTED
	const AUDIO_MUSIC_MUTED := GameConstants.Settings.AUDIO_MUSIC_MUTED
	const AUDIO_SFX_MUTED := GameConstants.Settings.AUDIO_SFX_MUTED
	const AUDIO_UI_MUTED := GameConstants.Settings.AUDIO_UI_MUTED
	const AUDIO_ENVIRONMENT_MUTED := GameConstants.Settings.AUDIO_ENVIRONMENT_MUTED
	const AUDIO_NARRATIVE_MUTED := GameConstants.Settings.AUDIO_NARRATIVE_MUTED

	const CONTROLS_INVERT_Y := GameConstants.Settings.CONTROLS_INVERT_Y
	const GAMEPLAY_DIFFICULTY := GameConstants.Settings.GAMEPLAY_DIFFICULTY
	const GAMEPLAY_ANIMATION_SPEED := GameConstants.Settings.GAMEPLAY_ANIMATION_SPEED
	const GAMEPLAY_BATCH_ANIMATIONS_ENABLED := GameConstants.Settings.GAMEPLAY_BATCH_ANIMATIONS_ENABLED
	const DISPLAY_ORIENTATION := GameConstants.Settings.DISPLAY_ORIENTATION
	const DISPLAY_RESOLUTION := GameConstants.Settings.DISPLAY_RESOLUTION
	const DISPLAY_LANGUAGE := GameConstants.Settings.LANGUAGE
	const DIALOGUE_AUTO_ADVANCE := GameConstants.Settings.DIALOGUE_AUTO_ADVANCE
	const DIALOGUE_AUTO_SPEED := GameConstants.Settings.DIALOGUE_AUTO_SPEED
	const DIALOGUE_TEXT_SPEED := GameConstants.Settings.DIALOGUE_TEXT_SPEED

	const ACCESSIBILITY_HIGH_CONTRAST := GameConstants.Settings.ACCESSIBILITY_HIGH_CONTRAST
	const ACCESSIBILITY_REDUCED_MOTION := GameConstants.Settings.ACCESSIBILITY_REDUCED_MOTION
	const ACCESSIBILITY_UI_SCALE := GameConstants.Settings.ACCESSIBILITY_UI_SCALE

const DEFAULT_CONFIG := {
	"audio": {
		"master_db": 0.0,
		"music_db": -3.0,
		"sfx_db": -3.0,
		"ui_db": -3.0,
		"environment_db": -3.0,
		"narrative_db": -3.0,
		"master_muted": false,
		"music_muted": false,
		"sfx_muted": false,
		"ui_muted": false,
		"environment_muted": false,
		"narrative_muted": false,
	},
	"controls": {
		"invert_y": false,
	},
	"gameplay": {
		"difficulty": GameConstants.Settings.DIFFICULTY_EASY,
		"animation_speed": GameConstants.Settings.ANIMATION_SPEED_NORMAL,
		"batch_animations_enabled": false,
	},
	"display": {
		"orientation": GameConstants.Settings.ORIENTATION_LANDSCAPE,
		"resolution": Vector2i(2560, 1440),
		"language": "en",
	},
	"dialogue": {
		"auto_advance_enabled": false,
		"auto_advance_speed": 1.0,
		"text_speed": GameConstants.UI.DIALOGUE_DEFAULT_TEXT_SPEED,
	},
	"accessibility": {
		"high_contrast_enabled": false,
		"reduced_motion_enabled": false,
		"ui_scale": 1.0,
	}
}

@export var config_path := "user://hex_config.cfg"
var _config: Dictionary = {}

func _ready() -> void:
	reset_to_defaults()
	load_config()

func reset_to_defaults() -> void:
	_config = DEFAULT_CONFIG.duplicate(true)

func set_value(path: String, value: Variant) -> void:
	_set_by_path(path, value)
	config_changed.emit(path, value)

func get_value(path: String, default_value: Variant = null) -> Variant:
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

			# Apply language immediately on load
			var lang: String = str(get_value(Paths.DISPLAY_LANGUAGE, "en"))
			TranslationServer.set_locale(lang)

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
	for key: Variant in update.keys():
		var value: Variant = update[key]
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
			base[key] = _deep_merge(base[key], value)
		else:
			base[key] = value
	return base
