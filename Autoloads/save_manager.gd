extends Node

const SAVE_FILE_PATH := "user://save_game.cfg"
const ROSTER_SAVE_PATH := "user://player_roster.tres"
const LOOTED_LEVELS_KEY := "looted_levels"

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
	else:
		set_value("player_roster_remaining_goals", roster.get_remaining_goal_titles())

func load_roster() -> PlayerRoster:
	if FileAccess.file_exists(ROSTER_SAVE_PATH):
		var resource = load(ROSTER_SAVE_PATH)
		if resource is PlayerRoster:
			var stored_titles = get_value("player_roster_remaining_goals", PackedStringArray())
			if stored_titles is PackedStringArray:
				resource.set_remaining_goal_titles(stored_titles)
			return resource
		else:
			push_warning("SaveManager: Loaded roster is not a PlayerRoster. Deleting invalid file. Path: " + ROSTER_SAVE_PATH)
			DirAccess.remove_absolute(ROSTER_SAVE_PATH)
			return null
	return null

func has_saved_roster() -> bool:
	return FileAccess.file_exists(ROSTER_SAVE_PATH)

func mark_level_looted(level_path: String) -> void:
	if level_path.is_empty():
		return
	var looted: Dictionary = _game_data.get(LOOTED_LEVELS_KEY, {})
	if typeof(looted) != TYPE_DICTIONARY:
		looted = {}
	looted[level_path] = true
	_game_data[LOOTED_LEVELS_KEY] = looted
	_save_data()

func is_level_looted(level_path: String) -> bool:
	if level_path.is_empty():
		return false
	var looted = _game_data.get(LOOTED_LEVELS_KEY, {})
	if typeof(looted) != TYPE_DICTIONARY:
		return false
	return looted.get(level_path, false)

func get_looted_levels_count() -> int:
	var looted: Dictionary = _game_data.get(LOOTED_LEVELS_KEY, {})
	if typeof(looted) != TYPE_DICTIONARY:
		return 0
	return looted.size()

func get_completed_levels_count() -> int:
	var completed: Dictionary = _game_data.get("completed_levels", {})
	if typeof(completed) != TYPE_DICTIONARY:
		return 0
	return completed.size()

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
