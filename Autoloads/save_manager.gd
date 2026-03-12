extends Node

const SAVE_FILE_PATH := "user://save_game.cfg"
var ROSTER_SAVE_PATH := "user://player_roster.tres"

var _is_dirty: bool = false
var _save_delay_timer: Timer

func _ready() -> void:
	_setup_timer()
	setup()

func _setup_timer() -> void:
	_save_delay_timer = Timer.new()
	_save_delay_timer.wait_time = 0.5
	_save_delay_timer.one_shot = true
	_save_delay_timer.timeout.connect(_perform_actual_save)
	add_child(_save_delay_timer)

## Initializes the manager and loads saved data.
func setup() -> void:
	# Disable verbose logging on release exports
	if not OS.is_debug_build():
		if Engine.has_singleton("LevelLog"):
			LevelLog.set_debug(false)
		else:
			# In case LevelLog is not an autoload, call by class if available
			LevelLog.set_debug(false)

	_load_data()
	
	# Initialize undo history with the loaded state
	if not _game_data.is_empty():
		save_current_state_for_undo()
	else:
		# If no save data, save an initial empty state
		_game_data = {}
		save_current_state_for_undo()

const LOOTED_LEVELS_KEY := "looted_levels"
const DEFAULT_LEADER_NAME := ""
const DEFAULT_PLAYER_ROSTER_PATH := RosterLoader.DEFAULT_PLAYER_ROSTER_PATH

var _game_data: Dictionary = {}
var _memento_history: Array = []
var _current_memento_index: int = -1
const MAX_MEMENTO_HISTORY_SIZE: int = 20 # Limit history size for performance/memory

# Structured flags
const GLOBAL_FLAGS_KEY := "global_flags"
const LEVEL_FLAGS_KEY := "level_flags"

func set_global_flag(flag_id: String, value: Variant) -> void:
	var flags = get_value(GLOBAL_FLAGS_KEY, {})
	flags[flag_id] = value
	set_value(GLOBAL_FLAGS_KEY, flags)

func get_global_flags() -> Dictionary:
	return get_value(GLOBAL_FLAGS_KEY, {})

func set_level_flag(level_id: String, flag_id: String, value: Variant) -> void:
	var all_level_flags = get_value(LEVEL_FLAGS_KEY, {})
	if not all_level_flags.has(level_id):
		all_level_flags[level_id] = {}
	all_level_flags[level_id][flag_id] = value
	set_value(LEVEL_FLAGS_KEY, all_level_flags)

func get_level_flags(level_id: String) -> Dictionary:
	var all_level_flags = get_value(LEVEL_FLAGS_KEY, {})
	return all_level_flags.get(level_id, {})

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
		if roster and roster.has_method("get_remaining_location_titles"):
			set_value("player_roster_remaining_locations", roster.get_remaining_location_titles())

func load_roster() -> PlayerRoster:
	var roster := _load_saved_roster_resource()
	if roster:
		# Sync logic: roster_entries is the source of truth for dynamic data
		if not roster.roster_entries.is_empty():
			_restore_roster_units(roster)
		
		if roster.units.is_empty():
			push_warning("SaveManager: Saved roster had no units; loading default core roster.")
			return _load_default_player_roster()
		return roster
	return _load_default_player_roster()

func has_saved_roster() -> bool:
	return FileAccess.file_exists(ROSTER_SAVE_PATH)

func set_hometown_skit_shown(skit_path: String, shown: bool) -> void:
	var skits: Dictionary = get_hometown_skits()
	skits[skit_path] = shown
	_game_data["hometown_skits_shown"] = skits
	_save_data()
	return

func get_hometown_skits() -> Dictionary:
	var skits: Dictionary = _game_data.get("hometown_skits_shown", {})
	if typeof(skits) != TYPE_DICTIONARY:
		return {}
	return skits

func get_leader_unit_name() -> String:
	var stored = _game_data.get("leader_unit_name", DEFAULT_LEADER_NAME)
	if typeof(stored) == TYPE_STRING and not String(stored).is_empty():
		return stored
	return DEFAULT_LEADER_NAME

func set_leader_unit_name(unit_name: String) -> void:
	if String(unit_name).is_empty():
		return
	_game_data["leader_unit_name"] = unit_name
	_save_data()

func get_completed_levels_count() -> int:
	var completed: Dictionary = _game_data.get("completed_levels", {})
	if typeof(completed) != TYPE_DICTIONARY:
		return 0
	return completed.size()

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print_debug("SaveManager: No save file found at ", SAVE_FILE_PATH)
		return

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var(true) # true for full_objects (Dictionaries)
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			_game_data = data
			print_debug("SaveManager: Loaded base save data keys: ", _game_data.keys())
			_distribute_loaded_data(_game_data)
		else:
			push_error("SaveManager: Corrupted save data. Expected Dictionary, got ", typeof(data))
	else:
		push_error("SaveManager: Could not open save file for reading: ", SAVE_FILE_PATH)

var _pending_memento: Dictionary = {}

func _save_data(memento: Dictionary = {}) -> void:
	_is_dirty = true
	if not memento.is_empty():
		_pending_memento = memento
	
	if is_inside_tree():
		if not is_instance_valid(_save_delay_timer):
			_setup_timer()
		_save_delay_timer.start()
	else:
		# Fallback for when not in tree (e.g. some unit tests)
		_perform_actual_save()

func _perform_actual_save() -> void:
	if not _is_dirty:
		return
		
	var data_to_save = _pending_memento if not _pending_memento.is_empty() else create_game_memento()
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data_to_save, true)
		file.close()
		_is_dirty = false
		_pending_memento = {}
		print_debug("SaveManager: Persistent state saved to disk.")
	else:
		push_error("SaveManager: Could not open save file for writing: ", SAVE_FILE_PATH)

# --- Memento Pattern Functions ---

# Originator: Creates a memento of the current game state
func create_game_memento(game_state: GameState = null) -> Dictionary:
	var memento_data = _game_data.duplicate(true) # Deep duplicate the base game data

	# Merge data from other managers
	var journal_manager = _get_journal_manager()
	if journal_manager:
		memento_data.merge(journal_manager.get_savable_data(), true)

	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		memento_data.merge(achievement_manager.get_savable_data(), true)

	# Capture current difficulty
	if GameConfig:
		memento_data["difficulty"] = GameConfig.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_EASY)

	# Capture weather state
	var weather_manager = get_node_or_null("/root/WeatherManager") if is_inside_tree() else null
	if weather_manager:
		memento_data["weather"] = weather_manager.create_memento()

	# TODO: Add other managers here that hold game state for a full undo/redo

	# Capture loot state
	if game_state and game_state.loot_manager and game_state.loot_manager.has_method("create_memento"):
		memento_data.merge(game_state.loot_manager.create_memento(), true)
	# Capture units with inventories
	if game_state and game_state.unit_manager:
		var unit_snaps: Array = []
		for u in game_state.unit_manager.get_units():
			if u:
				unit_snaps.append({
					"index": game_state.unit_manager.get_unit_index(u),
					"data": UnitSerializer.create_memento(u)
				})
		memento_data["units"] = unit_snaps
	# Capture player stash
	if game_state and game_state.player_roster and game_state.player_roster.has_method("create_memento"):
		memento_data.merge(game_state.player_roster.create_memento(), true)
	return memento_data

# Originator: Restores game state from a memento
func restore_game_state(memento: Dictionary) -> void:
	if memento == null:
		push_error("SaveManager: Attempted to restore from a null memento.")
		return

	_game_data = memento.duplicate(true) # Deep duplicate to restore base game data

func _distribute_loaded_data(data: Dictionary) -> void:
	var journal_manager = _get_journal_manager()
	if journal_manager:
		var _before_flags: Dictionary = journal_manager.get_savable_data() if journal_manager.has_method("get_savable_data") else {}
		journal_manager.load_savable_data(data)
		var after_data: Dictionary = journal_manager.get_savable_data() if journal_manager.has_method("get_savable_data") else {}
		# Log dialogue flags and journal entries if available
		if typeof(after_data) == TYPE_DICTIONARY:
			var dialogue_flags = after_data.get("dialogue_flags", {})
			var journal_entries = after_data.get("journal_entries", {})
			var dialogue_flags_count := 0
			if typeof(dialogue_flags) == TYPE_DICTIONARY:
				dialogue_flags_count = dialogue_flags.size()
			var journal_entries_count := 0
			if typeof(journal_entries) == TYPE_DICTIONARY:
				journal_entries_count = journal_entries.size()
			print_debug("SaveManager: Journal loaded. Dialogue flags count: ", dialogue_flags_count, ", Journal entries count: ", journal_entries_count)

	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		achievement_manager.load_savable_data(data)

	# Restore difficulty to GameConfig
	if data.has("difficulty") and GameConfig:
		GameConfig.set_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, data["difficulty"])

	# Restore weather state
	var weather_manager = get_node_or_null("/root/WeatherManager") if is_inside_tree() else null
	if data.has("weather") and weather_manager:
		weather_manager.restore_from_memento(data["weather"])

	# TODO: Add other managers here to load their respective parts of the memento

	# Player roster and related info
	if has_saved_roster():
		var roster := load_roster()
		if roster:
			var unit_names := []
			if roster.has_method("get_units"):
				for u in roster.get_units():
					unit_names.append(String(u.unit_name) if "unit_name" in u else str(u))
			print_debug("SaveManager: Roster loaded. Units: ", unit_names)
		else:
			print_debug("SaveManager: No saved roster found.")

func _load_saved_roster_resource() -> PlayerRoster:
	if not FileAccess.file_exists(ROSTER_SAVE_PATH):
		return null
	var resource = load(ROSTER_SAVE_PATH)
	if resource is PlayerRoster:
		return resource
	push_warning("SaveManager: Loaded roster is not a PlayerRoster. Deleting invalid file. Path: " + ROSTER_SAVE_PATH)
	DirAccess.remove_absolute(ROSTER_SAVE_PATH)
	return null

func _restore_roster_units(roster: PlayerRoster) -> void:
	if roster == null or roster.roster_entries.is_empty():
		return
	
	var rebuilt: Array[PackedScene] = []
	for entry in roster.roster_entries:
		var scene := RosterPersistence.entry_to_scene(entry)
		if scene:
			rebuilt.append(scene)
	
	if not rebuilt.is_empty():
		roster.units = rebuilt

func _load_default_player_roster() -> PlayerRoster:
	var fallback := _load_roster_from_resource(DEFAULT_PLAYER_ROSTER_PATH)
	if fallback:
		return fallback
	var loader := RosterLoader.new()
	return loader._build_core_player_roster()

func _load_roster_from_resource(path: String) -> PlayerRoster:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	if resource is PlayerRoster:
		return resource.duplicate(true)
	return null

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
	_save_data(memento)

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
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/JournalManager")

func _get_achievement_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/AchievementManager")

func get_all_skits() -> Array[Skit]:
	var skits: Array = _game_data.get("hometown_skits", [])
	if typeof(skits) != TYPE_ARRAY:
		return []
	var result: Array[Skit] = []

	for skit_dict in skits:
		var skit := Skit.new()
		skit.from_dict(skit_dict)
		result.append(skit)

	return result
