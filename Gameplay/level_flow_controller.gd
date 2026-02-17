class_name LevelFlowController
extends RefCounted

const LevelCatalog := preload("res://Resources/levels/level_catalog.gd")
const LevelProgressStore := preload("res://Gameplay/level_progress_store.gd")
const LevelSelect := preload("res://Menus/level_select.gd")

const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const TITLE_SCENE := "res://Menus/title_screen.tscn"
const CREDITS_SCENE := "res://Menus/credits.tscn"
const POST_COMPLETION_LEVEL_SELECT_SCENE := "res://Menus/level_select.tscn"

var _catalog: LevelCatalog
var _progress_store: LevelProgressStore
var _scene_tree: SceneTree
var _scene_transition: Node
var _current_level_id: String = ""
var _current_level_path: String = ""
var _pending_level_resource: Resource

func _init(catalog: LevelCatalog = null, progress_store: LevelProgressStore = null, scene_tree: SceneTree = null, scene_transition: Node = null) -> void:
	_catalog = catalog if catalog != null else LevelCatalog.new()
	_progress_store = progress_store if progress_store != null else LevelProgressStore.new(null)
	_scene_tree = scene_tree
	_scene_transition = scene_transition
	if is_instance_valid(_scene_tree):
		_scene_tree.scene_changed.connect(Callable(self, "_on_scene_changed").bind())

func start_level(level_id: String) -> void:
	var level_info := _catalog.get_level_by_id(level_id)
	if level_info.is_empty():
		push_error("LevelFlowController: Unknown level id", level_id)
		return
	if not is_level_unlocked(level_id):
		push_warning("LevelFlowController: Level locked", level_id)
		return
	_current_level_id = level_id
	_current_level_path = level_info.get("path", "")
	_pending_level_resource = _load_resource(_current_level_path)
	_change_scene(GAMEPLAY_SCENE)

func start_first_level() -> void:
	for entry in _catalog.get_levels():
		var level_id: String = entry.get("id", "")
		if level_id.is_empty():
			continue
		if is_level_unlocked(level_id):
			start_level(level_id)
			return
	push_warning("LevelFlowController: No unlocked levels available")

func mark_level_completed(level_id: String) -> void:
	_progress_store.mark_level_completed(level_id)

func get_available_levels() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _catalog.get_levels():
		var level_id: String = entry.get("id", "")
		if level_id == "":
			continue
		if is_level_unlocked(level_id):
			result.append(entry)
	return result

func is_level_unlocked(level_id: String) -> bool:
	var info := _catalog.get_level_by_id(level_id)
	if info.is_empty():
		return false
	var prerequisites: Array = info.get("prerequisites", [])
	for prereq in prerequisites:
		if not _progress_store.is_level_completed(prereq):
			return false
	return true

func get_level_info(level_id: String) -> Dictionary:
	return _catalog.get_level_by_id(level_id)

func get_current_level_path() -> String:
	return _current_level_path

func get_current_level_id() -> String:
	return _current_level_id

func handle_level_complete() -> void:
	if _current_level_id != "":
		mark_level_completed(_current_level_id)
	if _has_unlocked_incomplete_levels():
		_current_level_id = ""
		_current_level_path = ""
		LevelSelect.request_show_incomplete_only = true
		_change_scene(POST_COMPLETION_LEVEL_SELECT_SCENE)
	else:
		_current_level_id = ""
		_current_level_path = ""
		_change_scene(CREDITS_SCENE)

func handle_quit_to_title() -> void:
	_current_level_id = ""
	_current_level_path = ""
	_change_scene(TITLE_SCENE)

func handle_quit_to_level_select() -> void:
	_change_scene(POST_COMPLETION_LEVEL_SELECT_SCENE)

func _change_scene(target: String) -> void:
	if _scene_transition:
		if _scene_transition.has_method("is_changing") and _scene_transition.call("is_changing"):
			return
		_scene_transition.call_deferred("change_scene", target)
	elif is_instance_valid(_scene_tree):
		_scene_tree.change_scene_to_file(target)
	else:
		push_error("LevelFlowController: No SceneTree available to change scene to " + target)

func _set_next_level_by_path(path: String) -> void:
	var info := _catalog.find_level_by_path(path)
	_current_level_path = path
	_current_level_id = info.get("id", "")
	_pending_level_resource = _load_resource(path)

func _load_resource(path: String) -> Resource:
	if path == "":
		return null
	return load(path)

func _has_unlocked_incomplete_levels() -> bool:
	for entry in _catalog.get_levels():
		var level_id: String = entry.get("id", "")
		if level_id == "":
			continue
		if is_level_unlocked(level_id) and not _progress_store.is_level_completed(level_id):
			return true
	return false

func _on_scene_changed(new_scene: Node = null) -> void:
	var scene := new_scene if new_scene else (_scene_tree.current_scene if is_instance_valid(_scene_tree) else null)
	if scene == null:
		return
	if scene.scene_file_path == GAMEPLAY_SCENE:
		_configure_gameplay_scene(scene)

func _configure_gameplay_scene(scene: Node) -> void:
	if _pending_level_resource:
		scene.level_resource = _pending_level_resource
		if scene.has_method("set_level_and_rebuild"):
			scene.call_deferred("set_level_and_rebuild", _pending_level_resource)
		_pending_level_resource = null
	_connect_scene_signal(scene, "level_complete", Callable(self, "handle_level_complete"))
	_connect_scene_signal(scene, "quit_to_title", Callable(self, "handle_quit_to_title"))
	_connect_scene_signal(scene, "quit_to_level_select", Callable(self, "handle_quit_to_level_select"))

func _connect_scene_signal(scene: Node, signal_name: String, callable: Callable) -> void:
	if not scene.has_signal(signal_name):
		return
	if scene.is_connected(signal_name, callable):
		return
	scene.connect(signal_name, callable)
