class_name LevelProgressStore
extends RefCounted

const COMPLETED_LEVELS_KEY : String = GameConstants.Save.KEY_COMPLETED_LEVELS
const COMPLETION_HISTORY_KEY : String = GameConstants.Save.KEY_COMPLETION_HISTORY

var _save_manager: Node
var _completed_levels: Dictionary = {}
var _completion_history: Array = []

func _init(save_manager: Node = null) -> void:
	_save_manager = save_manager
	if _save_manager:
		_completed_levels = _save_manager.get_value(COMPLETED_LEVELS_KEY, {}).duplicate(true)
		_completion_history = _save_manager.get_value(COMPLETION_HISTORY_KEY, []).duplicate(true)

func get_completed_levels() -> Dictionary:
	return _completed_levels.duplicate(true)

func get_completion_history() -> Array:
	return _completion_history.duplicate(true)

func is_level_completed(level_id: String) -> bool:
	return _completed_levels.get(level_id, false)

func mark_level_completed(level_id: String, memento: Dictionary = {}, rounds: int = 0, turns: int = 0) -> void:
	if level_id == "":
		return
	_completed_levels[level_id] = true

	var history_entry := {
		"level_id": level_id,
		"timestamp": Time.get_datetime_dict_from_system(),
		"memento": memento,
		"rounds": rounds,
		"turns": turns
	}
	_completion_history.append(history_entry)

	if _save_manager:
		_save_manager.set_value(COMPLETED_LEVELS_KEY, _completed_levels)
		_save_manager.set_value(COMPLETION_HISTORY_KEY, _completion_history)
func reset() -> void:
	_completed_levels.clear()
	_completion_history.clear()
	if _save_manager:
		_save_manager.set_value(COMPLETED_LEVELS_KEY, _completed_levels)
		_save_manager.set_value(COMPLETION_HISTORY_KEY, _completion_history)
