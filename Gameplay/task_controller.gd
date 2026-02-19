class_name TaskController
extends Node

const StageResource := preload("res://Resources/task/stage.gd")
const TargetSpawner := preload("res://Gameplay/target_spawner.gd")

signal task_reached
signal game_over
signal dialogue_requested(dialogue_resource_path: String)
signal stage_dialogue_triggered(stage_id: StringName, dialogue_type: String)  # on_enter or on_exit

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _unit_controller: UnitController
var _turn_controller: TurnController
var _loot_manager: LootManager # New
var _combat_system: CombatSystem # New
var _grid: Node2D # New
var _task_reached_state: bool = false
var _game_over_state: bool = false
var _dialogue_queue: Array[String] = []  # Queue of dialogue paths to play sequentially
var _is_processing_dialogue_queue: bool = false

func setup(task_manager: TaskManager, unit_manager: UnitManager, unit_controller: UnitController = null, turn_controller: TurnController = null, loot_manager: LootManager = null, combat_system: CombatSystem = null, grid: Node2D = null) -> void:
	print_debug("[Task] setup() called with task_manager=%s" % ["valid" if task_manager else "null"])
	_task_manager = task_manager
	_unit_manager = unit_manager
	_unit_controller = unit_controller
	_turn_controller = turn_controller
	_loot_manager = loot_manager # Assign new parameter
	_combat_system = combat_system # Assign new parameter
	_grid = grid # Assign new parameter
	_dialogue_queue.clear()
	_is_processing_dialogue_queue = false
	if _task_manager:
		print_debug("[Task] Connecting to task_manager signals")
		if not _task_manager.task_completed.is_connected(on_task_completed):
			_task_manager.task_completed.connect(on_task_completed)
		if not _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.connect(_on_objective_updated)

		# If objective is already active, process it immediately
		# (it may have been started before this handler was connected)
		var active_obj = _task_manager.get_active_objective()
		var has_stage: String = "N/A"
		if active_obj and active_obj.current_stage != null:
			has_stage = "true"
		elif active_obj:
			has_stage = "false"
		print_debug("[Task] Checking for active objective: %s (is_active=%s, has_stage=%s)" % [
			"found" if active_obj else "null",
			str(active_obj.is_active) if active_obj else "N/A",
			has_stage
		])
		if active_obj and active_obj.is_active and active_obj.current_stage:
			print_debug("[Task] Objective already active during setup, triggering objective_updated handler...")
			_on_objective_updated(active_obj)
		else:
			print_debug("[Task] Objective not immediately processable in setup")
	else:
		print_debug("[Task] task_manager is null in setup!")

func on_unit_defeated(unit: Unit) -> void:
	# Check for defend unit failure
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			# Let objective handle death event
			obj.handle_event("unit_defeated", {"unit": unit})
	check_objective_conditions()

func on_task_completed(_index: int, _faction: int) -> void:
	check_objective_conditions()

func _on_objective_updated(objective: Resource) -> void:
	if objective and objective.is_active and objective.current_stage:
		_log_stage_transition(objective)
		print_debug("[Task] _on_objective_updated: Objective '%s' with stage '%s'" % [objective.title, objective.current_stage.id])
		_queue_stage_dialogues(objective.current_stage, "on_enter")
		_handle_stage_spawns(objective.current_stage)
		if objective.current_stage.start_dialogue_resource:
			var dialogue_id = objective.current_stage.start_dialogue_resource
			print_debug("[Task] Found start_dialogue_resource: %s" % dialogue_id)
			var dialogue_path = _resolve_dialogue_path(String(dialogue_id))
			if not dialogue_path.is_empty():
				_dialogue_queue.insert(0, dialogue_path)
				print_debug("[Task] Resolved to path: %s" % dialogue_path)
			else:
				print_debug("[Task] Failed to resolve dialogue path for: %s" % dialogue_id)
		print_debug("[Task] Dialogue queue size before processing: %d" % _dialogue_queue.size())
		_process_dialogue_queue()
	else:
		print_debug("[Task] _on_objective_updated called but objective inactive or no stage")
	check_objective_conditions()

func on_round_changed(current_round: int) -> void:
	if _task_manager == null:
		return

	var obj = _task_manager.get_active_objective()
	if obj:
		obj.handle_event("round_changed", {"round": current_round})

	check_objective_conditions()

func check_objective_conditions() -> void:
	if _task_reached_state or _game_over_state:
		return

	# Check inventory tasks
	if _unit_manager:
		var player_units: Array[Unit] = []
		for i in range(_unit_manager.get_unit_count()):
			var u = _unit_manager.get_unit(i)
			if u and u.faction == Unit.Faction.PLAYER and u.willpower > 0:
				player_units.append(u)
		check_inventory_objectives(player_units)

	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			if not obj.is_active: # Completed
				_log_objective_completed(obj)
				_task_reached_state = true
				task_reached.emit()
			elif _check_objective_failed(obj):
				_log_objective_failed(obj)
				_game_over_state = true
				game_over.emit()

func check_inventory_objectives(player_units: Array[Unit]) -> void:
	if _task_manager == null: return

	var obj = _task_manager.get_active_objective()
	if obj:
		obj.handle_event("inventory_check", {"units": player_units})

func _handle_stage_spawns(stage: Resource) -> void:
	if not stage.get("spawns") or stage.spawns.is_empty() or not _unit_controller:
		return

	for spawn in stage.spawns:
		TargetSpawner.spawn_unit(
			spawn,
			_unit_manager,
			_loot_manager,
			_task_manager,
			_combat_system,
			_grid
		)

	if _turn_controller:
		_turn_controller.rebuild_turn_roster()

func is_task_reached() -> bool:
	return _task_reached_state

func reset_task_state() -> void:
	_task_reached_state = false
	_game_over_state = false

func create_memento() -> Dictionary:
	if _task_manager:
		return _task_manager.create_memento()
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	if _task_manager:
		_task_manager.restore_from_memento(memento)


func get_task_info(task_id: String) -> Dictionary:
	if not _task_manager:
		return {}

	var task = _task_manager.get_task_by_id(task_id)
	if not task:
		return {}

	return {
		"id": task.id,
		"title": task.title,
		"description": task.description,
		"status": Task.Status.keys()[task.status] if task.status >= 0 else "UNKNOWN",
		"current_effort": task.current_effort,
		"effort_required": task.effort_required,
		"progress_ratio": task.get_progress_ratio(),
		"is_optional": task.is_optional,
		"icon": task.icon
	}

func _log_stage_transition(objective: Resource) -> void:
	if not objective or not objective.current_stage:
		return

	var stage = objective.current_stage
	var completed_count = 0
	for task in stage.active_tasks:
		if task.status == Task.Status.COMPLETED:
			completed_count += 1

	print_debug("[Task] Stage transitioned: '%s' | Tasks: %d/%d completed" %
		[stage.id, completed_count, stage.active_tasks.size()])

func _log_objective_completed(objective: Resource) -> void:
	if not objective:
		return
	print_debug("[Task] OBJECTIVE COMPLETED: '%s'" % objective.title)

func _log_objective_failed(objective: Resource) -> void:
	if not objective:
		return
	print_debug("[Task] OBJECTIVE FAILED: '%s'" % objective.title)

func _check_objective_failed(objective: Resource) -> bool:
	if not objective or not _unit_manager:
		return false

	# Check if all player units are defeated
	var alive_player_units = 0
	for i in range(_unit_manager.get_unit_count()):
		var u = _unit_manager.get_unit(i)
		if u and u.faction == Unit.Faction.PLAYER and u.willpower > 0:
			alive_player_units += 1

	# Fail if no player units remain
	if alive_player_units == 0:
		return true

	return false
func _trigger_stage_on_enter_dialogue(stage: Resource) -> void:
	"""Trigger on_enter dialogues for a stage when it becomes active."""
	if not stage or not stage.get("enter_dialogue_id"):
		return

	var dialogue_id = stage.get("enter_dialogue_id")
	if dialogue_id and not String(dialogue_id).is_empty():
		print_debug("[Task] Triggering stage on_enter dialogue: %s" % dialogue_id)
		# Emit signal so dialogue action service can handle it
		stage_dialogue_triggered.emit(stage.id if stage.get("id") else "unknown", "on_enter")

func _queue_stage_dialogues(stage: Resource, dialogue_type: String) -> void:
	"""Queue all transition dialogues for a stage (on_enter or on_exit)."""
	if not stage:
		print_debug("[Task] _queue_stage_dialogues: stage is null")
		return

	var dialogue_key = (dialogue_type + "_dialogue_id") if dialogue_type in ["on_enter", "on_exit"] else ""
	if dialogue_key.is_empty():
		print_debug("[Task] _queue_stage_dialogues: invalid dialogue_type '%s'" % dialogue_type)
		return

	var dialogue_id = stage.get(dialogue_key)
	print_debug("[Task] _queue_stage_dialogues: Looking for '%s' in stage (type: %s), found: %s" % [dialogue_key, dialogue_type, dialogue_id if dialogue_id else "NONE"])
	if dialogue_id and not String(dialogue_id).is_empty():
		var dialogue_path = _resolve_dialogue_path(String(dialogue_id))
		if not dialogue_path.is_empty():
			_dialogue_queue.append(dialogue_path)
			print_debug("[Task] Queued stage %s dialogue: %s (path: %s)" % [dialogue_type, dialogue_id, dialogue_path])
		else:
			print_debug("[Task] Failed to resolve dialogue path for: %s" % dialogue_id)
	else:
		print_debug("[Task] No dialogue_id found for %s" % dialogue_key)

func _resolve_dialogue_path(dialogue_id: String) -> String:
	"""Resolve a dialogue ID to a resource path."""
	# Try common dialogue locations
	var candidates = [
		"res://Resources/level_data/dialogues/%s.dialogue" % dialogue_id,
		"res://Resources/dialogues/%s.dialogue" % dialogue_id,
		dialogue_id if dialogue_id.ends_with(".dialogue") else ""
	]

	for path in candidates:
		if not path.is_empty():
			var exists = ResourceLoader.exists(path)
			print_debug("[Task] _resolve_dialogue_path: Checking '%s' - exists: %s" % [path, exists])
			if exists:
				return path

	# If no file exists, log warning but return the constructed path anyway
	# (it may be created dynamically)
	if dialogue_id.ends_with(".dialogue"):
		print_debug("[Task] _resolve_dialogue_path: Using dialogue_id directly: %s" % dialogue_id)
		return dialogue_id

	var default_path = "res://Resources/level_data/dialogues/%s.dialogue" % dialogue_id
	print_debug("[Task] _resolve_dialogue_path: No file found, returning default: %s" % default_path)
	return default_path

func _process_dialogue_queue() -> void:
	"""Process the dialogue queue, playing the next dialogue if available."""
	print_debug("[Task] _process_dialogue_queue called: processing=%s, queue_size=%d" % [_is_processing_dialogue_queue, _dialogue_queue.size()])
	if _is_processing_dialogue_queue or _dialogue_queue.is_empty():
		if _is_processing_dialogue_queue:
			print_debug("[Task] Already processing a dialogue, skipping")
		if _dialogue_queue.is_empty():
			print_debug("[Task] Dialogue queue is empty, nothing to play")
		return

	_is_processing_dialogue_queue = true
	var next_dialogue = _dialogue_queue.pop_front()
	print_debug("[Task] EMITTING dialogue_requested: %s (queue size: %d remaining)" % [next_dialogue, _dialogue_queue.size()])
	dialogue_requested.emit(next_dialogue)

func _on_dialogue_finished(flag: StringName = &"") -> void:
	"""Called when a dialogue finishes playing. Processes the next in queue."""
	print_debug("[Task] _on_dialogue_finished called (flag: %s), queue size: %d" % [flag, _dialogue_queue.size()])
	_is_processing_dialogue_queue = false
	if not _dialogue_queue.is_empty():
		_process_dialogue_queue()
	else:
		print_debug("[Task] Dialogue queue empty after finish")