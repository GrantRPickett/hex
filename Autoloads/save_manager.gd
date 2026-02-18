extends Node

const SAVE_FILE_PATH := "user://save_game.cfg"
const ROSTER_SAVE_PATH := "user://player_roster.tres"
const LOOTED_LEVELS_KEY := "looted_levels"
const DEFAULT_LEADER_NAME := ""

var _game_data: Dictionary = {}
var _memento_history: Array = []
var _current_memento_index: int = -1
const MAX_MEMENTO_HISTORY_SIZE: int = 20 # Limit history size for performance/memory

func _ready() -> void:
	_load_data()
	# Initialize undo history with the loaded state
	if not _game_data.is_empty():
		save_current_state_for_undo()
	else:
		# If no save data, save an initial empty state
		_game_data = {}
		save_current_state_for_undo()

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
		set_value("player_roster_remaining_locations", roster.get_remaining_location_titles())

func load_roster() -> PlayerRoster:
	if FileAccess.file_exists(ROSTER_SAVE_PATH):
		var resource = load(ROSTER_SAVE_PATH)
		if resource is PlayerRoster:
			var stored_titles = get_value("player_roster_remaining_locations", PackedStringArray())

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

func get_leader_unit_name() -> String:
	var stored = _game_data.get("leader_unit_name", DEFAULT_LEADER_NAME)
	if typeof(stored) == TYPE_STRING and not String(stored).is_empty():
		return stored
	return DEFAULT_LEADER_NAME

func set_leader_unit_name(name: String) -> void:
	if String(name).is_empty():
		return
	_game_data["leader_unit_name"] = name
	_save_data()

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
			_distribute_loaded_data(_game_data)
		else:
			push_error("SaveManager: Corrupted save data. Expected Dictionary, got ", typeof(data))
	else:
		push_error("SaveManager: Could not open save file for reading: ", SAVE_FILE_PATH)

func _save_data() -> void:
	var data_to_save = create_game_memento() # Use the memento creation logic
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data_to_save, true) # true for full_objects
		file.close()
	else:
		push_error("SaveManager: Could not open save file for writing: ", SAVE_FILE_PATH)

# --- Memento Pattern Functions ---

# Originator: Creates a memento of the current game state
func create_game_memento() -> Dictionary:
	var memento_data = _game_data.duplicate(true) # Deep duplicate the base game data

	# Merge data from other managers
	var journal_manager = _get_journal_manager()
	if journal_manager:
		memento_data.merge(journal_manager.get_savable_data(), true)

	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		memento_data.merge(achievement_manager.get_savable_data(), true)

	# TODO: Add other managers here that hold game state for a full undo/redo

	return memento_data

# Originator: Restores game state from a memento
func restore_game_state(memento: Dictionary) -> void:
	if memento == null:
		push_error("SaveManager: Attempted to restore from a null memento.")
		return

	_game_data = memento.duplicate(true) # Deep duplicate to restore base game data

	_distribute_loaded_data(_game_data)
	print_debug("SaveManager: Game state restored from memento.")

func _distribute_loaded_data(data: Dictionary) -> void:
	var journal_manager = _get_journal_manager()
	if journal_manager:
		journal_manager.load_savable_data(data)

	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		achievement_manager.load_savable_data(data)

	# TODO: Add other managers here to load their respective parts of the memento

# Caretaker: Saves the current state for undo
func save_current_state_for_undo() -> void:
	var memento = create_game_memento()

	# Clear any redo history if we're not at the end of the history
	if _current_memento_index < _memento_history.size() - 1:
		_memento_history.resize(_current_memento_index + 1)

	_memento_history.append(memento)
	_current_memento_index = _memento_history.size() - 1

	# Enforce history size limit
	if _memento_history.size() > MAX_MEMENTO_HISTORY_SIZE:
		_memento_history.remove_at(0)
		_current_memento_index -= 1
	print_debug("SaveManager: Saved state for undo. History size: ", _memento_history.size(), " Current index: ", _current_memento_index)

# Caretaker: Undoes to the previous state
func undo_state() -> bool:
	if _current_memento_index > 0:
		_current_memento_index -= 1
		restore_game_state(_memento_history[_current_memento_index])
		print_debug("SaveManager: Undo performed. Current index: ", _current_memento_index)
		return true
	print_debug("SaveManager: Cannot undo. Already at earliest state.")
	return false

# Caretaker: Redoes to the next state
func redo_state() -> bool:
	if _current_memento_index < _memento_history.size() - 1:
		_current_memento_index += 1
		restore_game_state(_memento_history[_current_memento_index])
		print_debug("SaveManager: Redo performed. Current index: ", _current_memento_index)
		return true
	print_debug("SaveManager: Cannot redo. Already at latest state.")
	return false

func _get_journal_manager() -> Node:
	if has_node("/root/journalManager"):
		return get_node("/root/journalManager")
	push_warning("SaveManager: JournalManager not found in /root.")
	return null

func _get_achievement_manager() -> Node:
	if has_node("/root/AchievementManager"):
		return get_node("/root/AchievementManager")
	push_warning("SaveManager: AchievementManager not found in /root.")
	return null
