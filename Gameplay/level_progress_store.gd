class_name LevelProgressStore
extends RefCounted

const COMPLETED_LEVELS_KEY := "completed_levels"

var _save_manager: Node
var _completed_levels: Dictionary = {}

func _init(save_manager: Node = null) -> void:
	_save_manager = save_manager
	if _save_manager:
		_completed_levels = _save_manager.get_value(COMPLETED_LEVELS_KEY, {}).duplicate(true)

func get_completed_levels() -> Dictionary:
	return _completed_levels.duplicate(true)

func is_level_completed(level_id: String) -> bool:
	return _completed_levels.get(level_id, false)

func mark_level_completed(level_id: String) -> void:
	if level_id == "":
		return
	_completed_levels[level_id] = true
	if _save_manager:
		_save_manager.set_value(COMPLETED_LEVELS_KEY, _completed_levels)

func reset() -> void:
	_completed_levels.clear()
	if _save_manager:
		_save_manager.set_value(COMPLETED_LEVELS_KEY, _completed_levels)
