class_name TaskDialogueHandler
extends Object

signal dialogue_requested(dialogue_resource_path: String)

var _dialogue_queue: Array[String] = []
var _is_processing_dialogue_queue: bool = false
var _state # GameState (type hint removed to avoid circular dependency)

func setup(state) -> void:
	_state = state
	_dialogue_queue.clear()
	_is_processing_dialogue_queue = false

func queue_stage_dialogues(stage: Resource, dialogue_type: String) -> void:
	if not stage:
		return

	var dialogue_resource_field = "start_dialogue_resource" if dialogue_type == "on_enter" else "exit_dialogue_resource"
	var dialogue_key = "enter_dialogue_id" if dialogue_type == "on_enter" else "exit_dialogue_id"

	var dialogue_res = stage.get(dialogue_resource_field) if stage.has_method("get") else ""
	if not String(dialogue_res).is_empty():
		_add_to_queue(dialogue_res)
		return

	var dialogue_id = stage.get(dialogue_key)
	if dialogue_id and not String(dialogue_id).is_empty():
		var dialogue_path = _resolve_dialogue_path(String(dialogue_id), stage)
		if not dialogue_path.is_empty():
			_add_to_queue(dialogue_path)

func queue_task_dialogues(stage: Resource, dialogue_type: String) -> void:
	if not stage or not stage.get("active_tasks"):
		return

	var tasks = stage.get("active_tasks") as Array
	for task in tasks:
		if not task: continue

		var dialogue_resource_field = "start_dialogue_resource" if dialogue_type == "on_enter" else "exit_dialogue_resource"
		var dialogue_key = "enter_dialogue_id" if dialogue_type == "on_enter" else "exit_dialogue_id"

		var dialogue_res = task.get(dialogue_resource_field) if task.has_method("get") else ""
		if not String(dialogue_res).is_empty():
			_add_to_queue(dialogue_res)
			continue

		var dialogue_id = task.get(dialogue_key)
		if dialogue_id and not String(dialogue_id).is_empty():
			var dialogue_path = _resolve_dialogue_path(String(dialogue_id), stage)
			if not dialogue_path.is_empty():
				_add_to_queue(dialogue_path)

func process_queue() -> void:
	if _is_processing_dialogue_queue or _dialogue_queue.is_empty():
		return

	_is_processing_dialogue_queue = true
	var next_dialogue = _dialogue_queue.pop_front()
	dialogue_requested.emit(next_dialogue)

func on_dialogue_finished() -> void:
	_is_processing_dialogue_queue = false
	process_queue()

func is_queue_empty() -> bool:
	return _dialogue_queue.is_empty()

func get_queue_contents() -> String:
	var contents = "["
	for i in range(_dialogue_queue.size()):
		if i > 0: contents += ", "
		contents += _dialogue_queue[i].get_file()
	contents += "]"
	return contents

func _add_to_queue(path: String) -> void:
	if not path in _dialogue_queue:
		_dialogue_queue.append(path)

func _resolve_dialogue_path(dialogue_id: String, stage: Resource) -> String:
	var level_prefix = ""
	if _state and _state.level:
		if _state.level.has_method("get"):
			var level_id = _state.level.get("level_id")
			if level_id and not String(level_id).is_empty():
				level_prefix = String(level_id)

		if level_prefix.is_empty():
			level_prefix = _state.level.resource_path.get_file().trim_suffix(".tres")

	if level_prefix.is_empty() and stage and stage.resource_path:
		var stage_file = stage.resource_path.get_file().trim_suffix(".tres")
		var last_underscore = stage_file.rfind("_")
		if last_underscore != -1:
			var remainder = stage_file.substr(last_underscore + 1)
			if not remainder.is_empty() and remainder.is_valid_int():
				level_prefix = stage_file.substr(0, last_underscore)

	var path = FilePaths.DynamicPaths.get_dialogue_path(level_prefix, dialogue_id)
	return path if ResourceLoader.exists(path) else ""
