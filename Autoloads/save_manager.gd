extends Node

const SAVE_FILE_PATH := "user://save_game.cfg"
const ROSTER_SAVE_PATH := "user://player_roster.tres"

var _game_data: Dictionary = {}

func _ready() -> void:
	_load_data()

func set_value(key: String, value: Variant) -> void:
	_game_data[key] = value
	_save_data()

func get_value(key: String, default: Variant = null) -> Variant:
	return _game_data.get(key, default)

func save_roster(roster: PlayerRoster) -> void:
	var error := ResourceSaver.save(roster, ROSTER_SAVE_PATH)
	if error != OK:
		push_error("SaveManager: Failed to save roster. Error code: ", error)

func load_roster() -> PlayerRoster:
	if FileAccess.file_exists(ROSTER_SAVE_PATH):
		var resource = load(ROSTER_SAVE_PATH)
		if resource is PlayerRoster:
			return resource
		else:
			push_warning("SaveManager: Loaded roster is not a PlayerRoster. Deleting invalid file. Path: " + ROSTER_SAVE_PATH)
			DirAccess.remove_absolute(ROSTER_SAVE_PATH)
			return null
	return null

func has_saved_roster() -> bool:
	return FileAccess.file_exists(ROSTER_SAVE_PATH)

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var(true) # true for full_objects (Dictionaries)
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			_game_data = data
		else:
			push_error("SaveManager: Corrupted save data. Expected Dictionary, got ", typeof(data))
	else:
		push_error("SaveManager: Could not open save file for reading: ", SAVE_FILE_PATH)

func _save_data() -> void:
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(_game_data, true) # true for full_objects
		file.close()
	else:
		push_error("SaveManager: Could not open save file for writing: ", SAVE_FILE_PATH)
