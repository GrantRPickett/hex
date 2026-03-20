extends Node

const SAVE_FILE_PATH : String = "user://save_game.cfg"
const DEFAULT_ROSTER_SAVE_PATH : String = "user://player_roster.tres"
var roster_save_path : String = DEFAULT_ROSTER_SAVE_PATH

# Hard-Save Configuration
const HARD_SAVE_SLOTS := 3
const HARD_SAVE_PATH_TEMPLATE := "user://hard_save_%d.cfg"
const HARD_SAVE_INDEX_KEY := "last_hard_save_index"

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
	var flags: Dictionary = get_value(GLOBAL_FLAGS_KEY, {})
	flags[flag_id] = value
	set_value(GLOBAL_FLAGS_KEY, flags)

func get_global_flags() -> Dictionary:
	return get_value(GLOBAL_FLAGS_KEY, {})

func set_level_flag(level_id: String, flag_id: String, value: Variant) -> void:
	var all_level_flags: Dictionary = get_value(LEVEL_FLAGS_KEY, {})
	if not all_level_flags.has(level_id):
		all_level_flags[level_id] = {}
	var level_data: Dictionary = all_level_flags[level_id]
	level_data[flag_id] = value
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
	var error := ResourceSaver.save(roster, roster_save_path)
	if error != OK:
		push_error("SaveManager: Failed to save roster. Error code: ", error)

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
	return FileAccess.file_exists(roster_save_path)

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

## Returns true if the game is currently set to Easy difficulty.
func is_easy_difficulty() -> bool:
	return get_value("difficulty", GameConstants.Settings.DIFFICULTY_NORMAL) == GameConstants.Settings.DIFFICULTY_EASY

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

	var data_to_save: Dictionary = _pending_memento if not _pending_memento.is_empty() else create_game_memento()
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data_to_save, true)
		file.close()
		_is_dirty = false
		_pending_memento = {}
		print_debug("SaveManager: Persistent state saved to disk.")
	else:
		push_error("SaveManager: Could not open save file for writing: ", SAVE_FILE_PATH)

## Creates a hard-save record for the current world state.
## Called before a level starts to provide a definitive recovery point.
func trigger_hard_save(level_id: String) -> void:
	var memento: Dictionary = create_game_memento()

	# Add metadata
	memento["save_timestamp"] = Time.get_datetime_dict_from_system()
	memento["level_id"] = level_id
	memento["completed_levels_count"] = get_completed_levels_count()
	memento["last_completed_level"] = get_value("last_completed_level_id", "None")
	memento["is_in_level"] = false # Hard-saves are always "pre-level" or "world state"

	# Determine slot via rotation
	var current_val: Variant = get_value(HARD_SAVE_INDEX_KEY, 0)
	var current_index: int = current_val if current_val is int else 0
	var next_index: int = (current_index + 1) % HARD_SAVE_SLOTS
	var save_path: String = HARD_SAVE_PATH_TEMPLATE % current_index

	# Persist hard-save
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(memento, true)
		file.close()
		set_value(HARD_SAVE_INDEX_KEY, next_index)
		print_debug("SaveManager: Hard-save created in slot %d for level %s" % [current_index, level_id])

		# ISOLATION: Flush mementos and undo history to prevent timeline jumping
		flush_mementos()
	else:
		push_error("SaveManager: Failed to write hard-save to: ", save_path)

## Returns metadata for all available hard-save slots.
func get_hard_save_metadata() -> Array[Dictionary]:
	var metadata: Array[Dictionary] = []
	for i in range(HARD_SAVE_SLOTS):
		var path: String = HARD_SAVE_PATH_TEMPLATE % i
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var data: Variant = file.get_var(true)
				file.close()
				if data is Dictionary:
					var dict_data: Dictionary = data
					metadata.append({
						"slot_index": i,
						"timestamp": dict_data.get("save_timestamp", {}),
						"level_id": dict_data.get("level_id", "Unknown"),
						"completed_count": dict_data.get("completed_levels_count", 0),
						"last_completed": dict_data.get("last_completed_level", "None")
					})
	return metadata

## Loads a hard-save from a specific slot.
func load_hard_save(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= HARD_SAVE_SLOTS:
		return false

	var path = HARD_SAVE_PATH_TEMPLATE % slot_index
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var(true)
		file.close()
		if data is Dictionary:
			restore_game_state(data)
			# ISOLATION: Flush mementos after loading a hard-save
			flush_mementos()
			return true
	return false

## Checks if there is a resumable in-level session.
func has_resumable_session() -> bool:
	return _game_data.get("is_in_level", false)

func get_last_hard_save_index() -> int:
	var current = get_value(HARD_SAVE_INDEX_KEY, 0)
	return (current - 1 + HARD_SAVE_SLOTS) % HARD_SAVE_SLOTS

## Flushes all mementos and resets undo history.
func flush_mementos() -> void:
	_memento_history.clear()
	_current_memento_index = -1
	save_current_state_for_undo() # Save new baseline
	print_debug("SaveManager: Memento history flushed.")

# --- Memento Pattern Functions ---

# Originator: Creates a memento of the current game state
func create_game_memento(game_state: GameState = null) -> Dictionary:
	var memento_data: Dictionary = _game_data.duplicate(true)
	_merge_system_data(memento_data)
	_capture_state_mementos(memento_data, game_state)
	return memento_data

func _merge_system_data(memento: Dictionary) -> void:
	var journal_manager = _get_journal_manager()
	if journal_manager:
		memento.merge(journal_manager.get_savable_data(), true)

	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		memento.merge(achievement_manager.get_savable_data(), true)

	if GameConfig:
		memento["difficulty"] = GameConfig.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_EASY)

func _capture_state_mementos(memento: Dictionary, game_state: GameState) -> void:

	if not game_state:
		memento["is_in_level"] = false
		return

	memento["is_in_level"] = true # Session is active if game_state is present
	if is_instance_valid(WeatherManager):
		memento["weather"] = WeatherManager.create_memento()

	if game_state.loot_manager and game_state.loot_manager.has_method("create_memento"):
		memento.merge(game_state.loot_manager.create_memento(), true)

	if game_state.turn_controller and game_state.turn_controller.has_method("create_memento"):
		memento["turn_state"] = game_state.turn_controller.create_memento()

	if game_state.task_manager and game_state.task_manager.has_method("create_memento"):
		memento["task_state"] = game_state.task_manager.create_memento()

	if game_state.location_service and game_state.location_service.has_method("create_memento"):
		memento["location_state"] = game_state.location_service.create_memento()

	if game_state.unit_manager:
		var unit_snaps: Array = []
		var units: Array = (game_state.unit_manager as UnitManager).get_units()
		for u_node: Node in units:
			if u_node is Unit:
				var u: Unit = u_node as Unit
				unit_snaps.append({
					"index": (game_state.unit_manager as UnitManager).get_unit_index(u),
					"data": UnitSerializer.create_memento(u)
				})
		memento["units"] = unit_snaps

	if game_state.player_roster and game_state.player_roster.has_method("create_memento"):
		memento.merge(game_state.player_roster.create_memento(), true)

# Originator: Restores game state from a memento
func restore_game_state(memento: Dictionary) -> void:
	if memento == null:
		push_error("SaveManager: Attempted to restore from a null memento.")
		return

	_game_data = memento.duplicate(true) # Deep duplicate to restore base game data

func _distribute_loaded_data(data: Dictionary) -> void:
	_distribute_journal_data(data)
	_distribute_achievement_data(data)
	_distribute_config_data(data)
	_distribute_weather_data(data)
	_distribute_roster_data()

	# Session state distribution
	_distribute_session_state(data)

func _distribute_session_state(data: Dictionary) -> void:
	if not is_inside_tree(): return

	var game_session = get_tree().root.get_node_or_null("GameSession")
	if not game_session or not "state" in game_session: return
	var game_state = game_session.get("state") # Use get() to avoid type issues if not present
	if not game_state: return

	if data.has("turn_state") and game_state.turn_controller:
		game_state.turn_controller.restore_from_memento(data["turn_state"])

	if data.has("task_state") and game_state.task_manager:
		game_state.task_manager.restore_from_memento(data["task_state"])

	if data.has("location_state") and game_state.location_service:
		game_state.location_service.restore_from_memento(data["location_state"])

func _distribute_config_data(data: Dictionary) -> void:
	if data.has("difficulty") and GameConfig:
		GameConfig.set_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, data["difficulty"])

func _distribute_roster_data() -> void:
	if has_saved_roster():
		var roster := load_roster()
		if roster:
			var unit_names := []
			if roster.has_method("get_units"):
				for u in roster.get_units():
					unit_names.append(String(u.unit_name) if "unit_name" in u else str(u))
			print_debug("SaveManager: Roster loaded. Units: ", unit_names)

func _distribute_journal_data(data: Dictionary) -> void:
	var journal_manager = _get_journal_manager()
	if not journal_manager:
		return

	journal_manager.load_savable_data(data)
	var after_data: Dictionary = journal_manager.get_savable_data() if journal_manager.has_method("get_savable_data") else {}
	if typeof(after_data) == TYPE_DICTIONARY:
		var dialogue_flags = after_data.get("dialogue_flags", {})
		var journal_entries = after_data.get("journal_entries", {})
		print_debug("SaveManager: Journal loaded. Dialogue flags count: ", dialogue_flags.size() if typeof(dialogue_flags) == TYPE_DICTIONARY else 0,
			", Journal entries count: ", journal_entries.size() if typeof(journal_entries) == TYPE_DICTIONARY else 0)

func _distribute_achievement_data(data: Dictionary) -> void:
	var achievement_manager = _get_achievement_manager()
	if achievement_manager:
		achievement_manager.load_savable_data(data)

func _distribute_weather_data(data: Dictionary) -> void:
	if data.has("weather") and is_instance_valid(WeatherManager):
		WeatherManager.restore_from_memento(data["weather"])


func _load_saved_roster_resource() -> PlayerRoster:
	if not FileAccess.file_exists(roster_save_path):
		return null
	var resource: Resource = load(roster_save_path)
	if resource is PlayerRoster:
		return resource
	push_warning("SaveManager: Loaded roster is not a PlayerRoster. Deleting invalid file. Path: " + roster_save_path)
	DirAccess.remove_absolute(roster_save_path)
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
	return loader.build_core_player_roster()

func _load_roster_from_resource(path: String) -> PlayerRoster:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
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
	return JournalManager if is_instance_valid(JournalManager) else null


func _get_achievement_manager() -> Node:
	return AchievementManager if is_instance_valid(AchievementManager) else null


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
