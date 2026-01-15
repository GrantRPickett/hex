extends Node

const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const TITLE_SCENE := "res://Menus/title_screen.tscn"
const CREDITS_SCENE := "res://Menus/credits.tscn"
const POST_COMPLETION_LEVEL_SELECT_SCENE := "res://Menus/level_select.tscn"

func start_level_by_id(level_id: String) -> void:
	var level_info = get_level_info(level_id)
	if level_info.is_empty():
		push_error("LevelManager: Attempted to start non-existent level ID: ", level_id)
		return

	_current_level_id = level_id
	_current_level_path = level_info["path"]

	if _scene_transition:
		if _scene_transition.is_changing():
			#print_debug("LevelManager: Already changing scene, cannot start level: ", level_id)
			return
		await _scene_transition.change_scene(GAMEPLAY_SCENE)
	else:
		get_tree().change_scene_to_file(GAMEPLAY_SCENE)

func start_first_level() -> void:
	for level_dict in _level_data:
		var level_id := String(level_dict.get("id", ""))
		if level_id.is_empty():
			continue
		if is_level_unlocked(level_id):
			start_level_by_id(level_id)
			return
	push_warning("LevelManager: No unlocked levels available to start.")


# New data structure for level metadata
var _level_data: Array[Dictionary] = []
var _completed_levels: Dictionary = {} # Stores "level_id": true for completed levels
var _current_level_id: String = ""
var _current_level_path: String = ""

const LEVEL_METADATA: Array[Dictionary] = [
	{"id": "level_1", "path": "res://Resources/levels/level_1.tres", "display_name": "The Beginning", "prerequisites": []},
	{"id": "level_2", "path": "res://Resources/levels/level_2.tres", "display_name": "Crossroads", "prerequisites": ["level_1"]},
	{"id": "level_3", "path": "res://Resources/levels/level_3.tres", "display_name": "Fork in the Road", "prerequisites": ["level_1"]},
	{"id": "level_4", "path": "res://Resources/levels/level_4.tres", "display_name": "Branching Path", "prerequisites": ["level_1"]},
	{"id": "level_5", "path": "res://Resources/levels/level_5.tres", "display_name": "Twin Peaks", "prerequisites": ["level_2", "level_3"]},
	{"id": "level_6", "path": "res://Resources/levels/level_6.tres", "display_name": "Confluence", "prerequisites": ["level_3", "level_4"]},
	{"id": "level_7", "path": "res://Resources/levels/level_7.tres", "display_name": "The Nexus", "prerequisites": ["level_2", "level_4"]},
]

var _save_manager: Node
var _scene_transition: Node

func _ready() -> void:
	_level_data = LEVEL_METADATA.duplicate(true)

	# The _save_manager can be overridden by tests via set("_save_manager", ...).
	# Otherwise, it defaults to the global singleton.
	if not _save_manager:
		_save_manager = get_tree().root.get_node_or_null("SaveManager")

	if not _scene_transition:
		_scene_transition = get_node_or_null("/root/SceneTransition")

	if _save_manager:
		_completed_levels = _save_manager.get_value("completed_levels", {})
	else:
		push_error("SaveManager Autoload not found! (LevelManager._ready)")

	get_tree().scene_changed.connect(_on_scene_changed)
	# Ensure we attach to the currently running scene if present
	_on_scene_changed()

func get_level_info(level_id: String) -> Dictionary:
	for level_dict in _level_data:
		if level_dict["id"] == level_id:
			return level_dict
	return {}

func is_level_unlocked(level_id: String) -> bool:
	var level_info = get_level_info(level_id)
	if level_info.is_empty():
		return false # Level not found

	if level_info["prerequisites"].is_empty():
		return true # No prerequisites, so always unlocked

	for prereq_id in level_info["prerequisites"]:
		if not _completed_levels.has(prereq_id):
			return false # A prerequisite is not met
	return true # All prerequisites are met

func mark_level_completed(level_id: String) -> void:
	_completed_levels[level_id] = true
	# Save updated completed levels via SaveManager
	if _save_manager:
		_save_manager.set_value("completed_levels", _completed_levels)
	else:
		push_error("SaveManager not found! (LevelManager.mark_level_completed)")

func get_available_levels() -> Array[Dictionary]:
	var available_levels: Array[Dictionary] = []
	for level_dict in _level_data:
		if is_level_unlocked(level_dict["id"]):
			available_levels.append(level_dict)
	return available_levels



func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.has_signal("level_complete"):
		if not scene.level_complete.is_connected(_on_level_complete):
			scene.level_complete.connect(_on_level_complete)
	if scene.has_signal("quit_to_title"):
		if not scene.quit_to_title.is_connected(_on_quit_to_title):
			scene.quit_to_title.connect(_on_quit_to_title)

func _on_quit_to_title() -> void:
	##print_debug("DBG level_manager _on_quit_to_title called")
	if _scene_transition:
		if _scene_transition.is_changing():
			##print_debug("DBG level_manager _on_quit_to_title ignored: already changing")
			return
		await _scene_transition.change_scene(TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)

func _on_level_complete() -> void: # No argument needed as we track current level internally
	if _scene_transition and _scene_transition.is_changing():
		return

	if _current_level_id != "":
		mark_level_completed(_current_level_id)
		#print_debug("LevelManager: Marked '", _current_level_id, "' as completed.")

	# Check for any unlocked AND incomplete levels
	var has_unlocked_incomplete_levels := false
	for level_dict in _level_data:
		if is_level_unlocked(level_dict["id"]) and not _completed_levels.has(level_dict["id"]):
			has_unlocked_incomplete_levels = true
			break

	if has_unlocked_incomplete_levels:
		#print_debug("LevelManager: Unlocked and incomplete levels available. Transitioning to post-completion level select.")
		_current_level_id = "" # Clear current level as we're going to a menu
		_current_level_path = ""
		if _scene_transition:
			await _scene_transition.change_scene(POST_COMPLETION_LEVEL_SELECT_SCENE)
		else:
			get_tree().change_scene_to_file(POST_COMPLETION_LEVEL_SELECT_SCENE)
	else:
		#print_debug("LevelManager: No more unlocked and incomplete levels found. Transitioning to credits.")
		_current_level_id = "" # Reset current level as game finished
		_current_level_path = ""
		if _scene_transition:
			await _scene_transition.change_scene(CREDITS_SCENE)
		else:
			get_tree().change_scene_to_file(CREDITS_SCENE)
