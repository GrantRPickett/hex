class_name TaskDialogueHandler
extends Object

signal dialogue_requested(dialogue_resource_path: String, flag_id: StringName)

var _dialogue_queue: Array[Dictionary] = [] # Stores { "path": String, "flag_id": StringName }
var _is_processing_dialogue_queue: bool = false
var _current_dialogue: String = ""
var _state # GameState (type hint removed to avoid circular dependency)

func setup(state: GameState) -> void:
	_state = state
	_dialogue_queue.clear()
	_is_processing_dialogue_queue = false
	_current_dialogue = ""

func queue_stage_dialogues(stage: Stage, dialogue_type: String) -> void:
	if not stage:
		return

	var dialogue_resource_field: String = "start_dialogue_resource" if dialogue_type == "on_enter" else "exit_dialogue_resource"
	var dialogue_key: String = "enter_dialogue_id" if dialogue_type == "on_enter" else "exit_dialogue_id"

	var dialogue_res: String = stage.get(dialogue_resource_field)
	var flag_id: StringName = StringName(str(stage.get(dialogue_key)))
	
	if dialogue_res is String and not dialogue_res.is_empty():
		_add_to_queue(dialogue_res, flag_id)
		return

	if not flag_id.is_empty():
		var dialogue_path: String = _resolve_dialogue_path(str(flag_id), stage)
		if not dialogue_path.is_empty():
			_add_to_queue(dialogue_path, flag_id)

func queue_task_dialogues(stage: Stage, dialogue_type: String) -> void:
	if not stage or stage.active_tasks.is_empty():
		return

	for task: Task in stage.active_tasks:
		if not task: continue

		var dialogue_resource_field: String = "start_dialogue_resource" if dialogue_type == "on_enter" else "exit_dialogue_resource"
		var dialogue_key: String = "enter_dialogue_id" if dialogue_type == "on_enter" else "exit_dialogue_id"

		var dialogue_res = task.get(dialogue_resource_field)
		var flag_id: StringName = StringName(str(task.get(dialogue_key)))
		
		if dialogue_res is String and not dialogue_res.is_empty():
			_add_to_queue(dialogue_res, flag_id)
			continue

		if not flag_id.is_empty():
			var dialogue_path: String = _resolve_dialogue_path(str(flag_id), stage)
			if not dialogue_path.is_empty():
				_add_to_queue(dialogue_path, flag_id)

func queue_dialogue(path: String, d_id: StringName = &"") -> void:
	if not path.is_empty():
		_add_to_queue(path, d_id)

func process_queue() -> void:
	if _is_processing_dialogue_queue or _dialogue_queue.is_empty():
		return

	_is_processing_dialogue_queue = true
	var entry = _dialogue_queue.pop_front()
	_current_dialogue = entry.path
	dialogue_requested.emit(entry.path, entry.flag_id)

func on_dialogue_finished() -> void:
	print_debug("[TaskDialogueHandler] on_dialogue_finished() START - isProcessing=", _is_processing_dialogue_queue, " currentDialogue=", _current_dialogue)
	_is_processing_dialogue_queue = false
	_current_dialogue = ""
	print_debug("[TaskDialogueHandler] on_dialogue_finished() - State cleared, processing next in queue...")
	process_queue()

func is_queue_empty() -> bool:
	return _dialogue_queue.is_empty()

func is_processing() -> bool:
	return _is_processing_dialogue_queue

func get_queue_contents() -> String:
	var contents: String = "["
	for i in range(_dialogue_queue.size()):
		if i > 0: contents += ", "
		contents += _dialogue_queue[i].path.get_file()
	contents += "]"
	return contents

func _add_to_queue(path: String, flag_id: StringName = &"") -> void:
	if path == _current_dialogue:
		return
	
	for entry in _dialogue_queue:
		if entry.path == path:
			return
			
	_dialogue_queue.append({"path": path, "flag_id": flag_id})

func _resolve_dialogue_path(dialogue_id: String, stage: Stage) -> String:
	var level_prefix: String = ""
	if _state and _state.level:
		var level_res: Resource = _state.level
		var level_id = level_res.get("level_id")
		if level_id != null and not str(level_id).is_empty():
			level_prefix = str(level_id)

		if level_prefix.is_empty():
			var res_path: String = level_res.resource_path
			if not res_path.is_empty():
				level_prefix = res_path.get_file().trim_suffix(".tres")

	if level_prefix.is_empty() and stage and not stage.resource_path.is_empty():
		var stage_file: String = stage.resource_path.get_file().trim_suffix(".tres")
		var last_underscore: int = stage_file.rfind("_")
		if last_underscore != -1:
			var remainder: String = stage_file.substr(last_underscore + 1)
			if not remainder.is_empty() and remainder.is_valid_int():
				level_prefix = stage_file.substr(0, last_underscore)

	var path: String = FilePaths.DynamicPaths.get_dialogue_path(level_prefix, dialogue_id)
	return path if ResourceLoader.exists(path) else ""
