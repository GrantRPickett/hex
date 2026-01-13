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

	if Engine.has_singleton("SceneTransition"):
		if SceneTransition.is_changing():
			#print_debug("LevelManager: Already changing scene, cannot start level: ", level_id)
			return
		await SceneTransition.change_scene(GAMEPLAY_SCENE)
	else:
		get_tree().change_scene_to_file(GAMEPLAY_SCENE)

# New data structure for level metadata
var _level_data: Array[Dictionary] = []
var _completed_levels: Dictionary = {} # Stores "level_id": true for completed levels
var _current_level_id: String = ""
var _current_level_path: String = ""

const LEVEL_METADATA: Array[Dictionary] = [
	{"id": "level1", "path": "res://Resources/levels/level1.tres", "display_name": "The Beginning", "prerequisites": []},
	{"id": "level2", "path": "res://Resources/levels/level2.tres", "display_name": "Crossroads", "prerequisites": ["level1"]},
	{"id": "level3", "path": "res://Resources/levels/level3.tres", "display_name": "Fork in the Road", "prerequisites": ["level1"]},
	{"id": "level4", "path": "res://Resources/levels/level4.tres", "display_name": "Branching Path", "prerequisites": ["level1"]},
	{"id": "level5", "path": "res://Resources/levels/level5.tres", "display_name": "Twin Peaks", "prerequisites": ["level2", "level3"]},
	{"id": "level6", "path": "res://Resources/levels/level6.tres", "display_name": "Confluence", "prerequisites": ["level3", "level4"]},
	{"id": "level7", "path": "res://Resources/levels/level7.tres", "display_name": "The Nexus", "prerequisites": ["level2", "level4"]},
]

func _ready() -> void:
	_level_data = LEVEL_METADATA.duplicate(true)
	# Load completed levels from SaveManager
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager != null:
		_completed_levels = save_manager.get_value("completed_levels", {})
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
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager != null:
		save_manager.set_value("completed_levels", _completed_levels)
	else:
		push_error("SaveManager Autoload not found! (LevelManager.mark_level_completed)")

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
		if scene.is_connected("level_complete", Callable(self, "_on_level_complete")):
			scene.disconnect("level_complete", Callable(self, "_on_level_complete"))
		scene.level_complete.connect(_on_level_complete)
	if scene.has_signal("quit_to_title"):
		if scene.is_connected("quit_to_title", Callable(self, "_on_quit_to_title")):
			scene.disconnect("quit_to_title", Callable(self, "_on_quit_to_title"))
		scene.quit_to_title.connect(_on_quit_to_title)

func _on_quit_to_title() -> void:
	##print_debug("DBG level_manager _on_quit_to_title called")
	if Engine.has_singleton("SceneTransition"):
		if SceneTransition.is_changing():
			##print_debug("DBG level_manager _on_quit_to_title ignored: already changing")
			return
		await SceneTransition.change_scene(TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)

func _on_level_complete() -> void: # No argument needed as we track current level internally
	if Engine.has_singleton("SceneTransition") and SceneTransition.is_changing():
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
		if Engine.has_singleton("SceneTransition"):
			await SceneTransition.change_scene(POST_COMPLETION_LEVEL_SELECT_SCENE)
		else:
			get_tree().change_scene_to_file(POST_COMPLETION_LEVEL_SELECT_SCENE)
	else:
		#print_debug("LevelManager: No more unlocked and incomplete levels found. Transitioning to credits.")
		_current_level_id = "" # Reset current level as game finished
		_current_level_path = ""
		if Engine.has_singleton("SceneTransition"):
			await SceneTransition.change_scene(CREDITS_SCENE)
		else:
			get_tree().change_scene_to_file(CREDITS_SCENE)
