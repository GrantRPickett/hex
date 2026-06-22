class_name DialogueState
extends Object

## Typed state object for Nathan Hoad's Dialogue Manager.
## Allows accessing unit names and game state variables in .dialogue files.

var initiator_name: String = ""
var partner_name: String = ""
var level_id: String = ""

## Persistent flags from save data, filtered for the current level.
var flags: Dictionary = {}

## Character states (stats, status) for units in the current level.
var characters: Dictionary = {}

signal flag_changed(flag_name: String, value: Variant)

# Helper to check a flag easily in dialogue: if has_flag("some_flag")
func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func get_character_stat(char_name: String, stat_name: String, default: Variant = null) -> Variant:
	if characters.has(char_name):
		return characters[char_name].get(stat_name, default)
	return default

func get_character(char_name: String) -> Dictionary:
	return characters.get(char_name, {})
