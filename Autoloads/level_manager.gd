extends Node

const LevelCatalog := preload("res://Resources/levels/level_catalog.gd")
const LevelProgressStore := preload("res://Gameplay/level_progress_store.gd")
const LevelFlowController := preload("res://Gameplay/level_flow_controller.gd")

const TITLE_SCENE := LevelFlowController.TITLE_SCENE
const POST_COMPLETION_LEVEL_SELECT_SCENE := LevelFlowController.POST_COMPLETION_LEVEL_SELECT_SCENE

var _catalog: LevelCatalog
var _progress_store: LevelProgressStore
var _flow: LevelFlowController
var _save_manager: Node
var _scene_transition: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _catalog == null:
		_catalog = LevelCatalog.new()
	if not _save_manager:
		_save_manager = get_tree().root.get_node_or_null("SaveManager")
	if not _scene_transition:
		_scene_transition = get_node_or_null("/root/SceneTransition")
	_progress_store = LevelProgressStore.new(_save_manager)
	_flow = LevelFlowController.new(_catalog, _progress_store, get_tree(), _scene_transition)

func start_level_by_id(level_id: String) -> void:
	_flow.start_level(level_id)

func start_first_level() -> void:
	_flow.start_first_level()

func get_level_info(level_id: String) -> Dictionary:
	return _flow.get_level_info(level_id)

func is_level_unlocked(level_id: String) -> bool:
	return _flow.is_level_unlocked(level_id)

func mark_level_completed(level_id: String) -> void:
	_flow.mark_level_completed(level_id)

func get_available_levels() -> Array[Dictionary]:
	return _flow.get_available_levels()

func get_current_level_path() -> String:
	return _flow.get_current_level_path()

func get_current_level_id() -> String:
	return _flow.get_current_level_id()

func is_level_completed(level_id: String) -> bool:
	if _progress_store == null:
		return false
	return _progress_store.is_level_completed(level_id)

func reset_completed_levels() -> void:
	if _progress_store:
		_progress_store.reset()

func _on_level_complete(next_level_path: String = "") -> void:
	_flow.handle_level_complete(next_level_path)

func _on_quit_to_title() -> void:
	_flow.handle_quit_to_title()

func _on_quit_to_level_select() -> void:
	_flow.handle_quit_to_level_select()
