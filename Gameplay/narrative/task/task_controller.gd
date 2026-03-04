class_name TaskController
extends Node
signal task_reached
signal game_over
signal dialogue_requested(dialogue_resource_path: String)
signal stage_dialogue_triggered(stage_id: StringName, dialogue_type: String) # on_enter or on_exit

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _unit_controller: UnitController
var _turn_controller: TurnController
var _loot_manager: LootManager
var _combat_system: CombatSystem
var _state: GameState
var _task_reached_state: bool = false
var _game_over_state: bool = false
var _dialogue_queue: Array[String] = [] # Queue of dialogue paths to play sequentially
var _is_processing_dialogue_queue: bool = false
var _current_stage_id: StringName = &"" # Track which stage we're currently processing to avoid duplicate queueing
var level: Level

func setup(state: GameState) -> void:
	print_debug("[Task] setup() called with state=%s" % ["valid" if state else "null"])
	_task_manager = state.task_manager
	_unit_manager = state.unit_manager
	_unit_controller = state.unit_controller
	_turn_controller = state.turn_controller
	_loot_manager = state.loot_manager
	_combat_system = state.combat_system
	_state = state
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
		else:
			print_debug("[Task] Objective not immediately processable in setup")
	else:
		print_debug("[Task] task_manager is null in setup!")

	# Connect round change to update countdown-style tasks
	if _turn_controller and not _turn_controller.round_changed.is_connected(on_round_changed):
		_turn_controller.round_changed.connect(on_round_changed)

func set_level(current_level: Level) -> void:
	print_debug("[Task] set_level called with current_level=%s" % [current_level.resource_path if current_level else "null"])
	self.level = current_level
	if _task_manager:
		_task_manager.set_level_and_objective(current_level, current_level.objective)

func on_unit_defeated(unit: Unit) -> void:
	# Check for defend unit failure
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			# Let objective handle death event
			obj.handle_event("unit_defeated", {"unit": unit})
	check_objective_conditions()

func _on_stage_completed(_next_stage: Stage, completing_stage: Stage) -> void:
	"""Called when a stage completes. Queue its exit dialogues."""
	if completing_stage:
		print_debug("[Task] Stage '%s' completed, queuing exit dialogues..." % completing_stage.id)
		_queue_task_dialogues(completing_stage, "on_exit")
		_queue_stage_dialogues(completing_stage, "on_exit")
		# Reset current stage so the next stage can be queued when objective_updated fires
		_current_stage_id = &""
		if not _dialogue_queue.is_empty() and not _is_processing_dialogue_queue:
			_process_dialogue_queue()

func _on_stage_failed(failing_stage: Stage) -> void:
	"""Called when a stage fails. Queue its exit dialogues."""
	if failing_stage:
		print_debug("[Task] Stage '%s' failed, queuing exit dialogues..." % failing_stage.id)
		_queue_task_dialogues(failing_stage, "on_exit")
		_queue_stage_dialogues(failing_stage, "on_exit")
		if not _dialogue_queue.is_empty() and not _is_processing_dialogue_queue:
			_process_dialogue_queue()

func on_task_completed(_index: int, _faction: int) -> void:
	check_objective_conditions()

func _on_objective_updated(objective: Resource) -> void:
	if objective and objective.is_active and objective.current_stage:
		var stage = objective.current_stage
		var stage_id = stage.get("id") if stage.has_method("get") else &""

		# Skip if we've already queued dialogues for this stage (prevents duplicate queueing)
		if stage_id == _current_stage_id:
			print_debug("[Task] _on_objective_updated: Skipping duplicate stage '%s' (already queued)" % stage_id)
			return

		_current_stage_id = stage_id
		_log_stage_transition(objective)
		print_debug("[Task] _on_objective_updated: Objective '%s' with stage '%s'" % [objective.title, stage_id])
		# Connect to stage completion signals to queue exit dialogues
		if not stage.stage_completed.is_connected(_on_stage_completed):
			stage.stage_completed.connect(_on_stage_completed.bindv([stage]))
		if not stage.stage_failed.is_connected(_on_stage_failed):
			stage.stage_failed.connect(_on_stage_failed.bindv([stage]))

		print_debug("[Task] === QUEUEING STAGE DIALOGUES ===")
		_queue_stage_dialogues(stage, "on_enter")
		print_debug("[Task] Queue size after stage dialogues: %d" % _dialogue_queue.size())

		print_debug("[Task] === QUEUEING TASK DIALOGUES ===")
		_queue_task_dialogues(stage, "on_enter")
		print_debug("[Task] Queue size after task dialogues: %d" % _dialogue_queue.size())

		_handle_stage_spawns(stage)
		var queue_contents = "["
		for i in range(_dialogue_queue.size()):
			if i > 0:
				queue_contents += ", "
			queue_contents += _dialogue_queue[i].get_file()
		queue_contents += "]"
		print_debug("[Task] Final dialogue queue: %s" % queue_contents)
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
	if not _unit_manager or not _state.grid_controller:
		return

	var spawn_occurred := false
	var grid = _state.grid_controller.get_grid()

	# Collect all spawns from various possible arrays (for compatibility)
	var all_spawns: Array = []

	var enemy_spawns = stage.get("enemy_spawns") if stage.has_method("get") else []
	if not enemy_spawns.is_empty():
		all_spawns.append_array(enemy_spawns)

	var neutral_spawns = stage.get("neutral_spawns") if stage.has_method("get") else []
	if not neutral_spawns.is_empty():
		all_spawns.append_array(neutral_spawns)

	var legacy_spawns = stage.get("spawns") if stage.has_method("get") else []
	if not legacy_spawns.is_empty():
		# Only append if not already present or if we want to support both
		all_spawns.append_array(legacy_spawns)

	for spawn in all_spawns:
		if not spawn:
			continue

		var unit = TargetSpawner.spawn_unit(
			spawn,
			_unit_manager,
			_loot_manager,
			_task_manager,
			_combat_system,
			grid
		)

		if unit:
			spawn_occurred = true

	if spawn_occurred and _turn_controller:
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

	return _transform_task_to_info(task)

func get_task_at_coord(coord: Vector2i) -> Dictionary:
	if not _task_manager:
		return {}

	var location = _task_manager.get_location_at(coord)
	var tasks: Array[Task] = []
	if location:
		tasks = _task_manager.get_active_tasks_for_target(location)

	if tasks.is_empty():
		var loot = _task_manager.get_loot_at(coord)
		if loot:
			tasks = _task_manager.get_active_tasks_for_target(loot)

	if not tasks.is_empty():
		var task = tasks[0]
		return _transform_task_to_info(task)

	return {}

func _transform_task_to_info(task: Task) -> Dictionary:
	return {
		"id": task.id,
		"title": task.title,
		"description": task.description,
		"status": Task.Status.keys()[task.status] if task.status >= 0 else "UNKNOWN",
		"current": task.current_effort,
		"required": task.effort_required,
		"completed": task.status == Task.Status.COMPLETED,
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

	var total_units = _unit_manager.get_unit_count()
	if total_units == 0:
		return false # Too early to fail (initialization)

	# Check if all player units are defeated
	var player_units = _unit_manager.get_player_units()
	if player_units.is_empty():
		return true # Enemies exist but no players remain

	var alive_player_units = 0
	for u in player_units:
		if is_instance_valid(u) and u.willpower > 0:
			alive_player_units += 1

	# Fail if no player units remain alive
	return alive_player_units == 0


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

	var dialogue_resource_field = ""
	var dialogue_key = ""

	if dialogue_type == "on_enter":
		dialogue_resource_field = "start_dialogue_resource"
		dialogue_key = "enter_dialogue_id"
	elif dialogue_type == "on_exit":
		dialogue_resource_field = "exit_dialogue_resource"
		dialogue_key = "exit_dialogue_id"
	else:
		print_debug("[Task] _queue_stage_dialogues: invalid dialogue_type '%s'" % dialogue_type)
		return

	# Try to use the pre-built dialogue resource first
	var dialogue_res = stage.get(dialogue_resource_field) if stage.has_method("get") else ""
	if not String(dialogue_res).is_empty():
		if not dialogue_res in _dialogue_queue:
			_dialogue_queue.append(dialogue_res)
			print_debug("[Task] Queued stage %s from %s: %s (queue size now: %d)" % [dialogue_type, dialogue_resource_field, dialogue_res.get_file(), _dialogue_queue.size()])
		else:
			print_debug("[Task] Skipped duplicate: %s" % dialogue_res)
		return

	# Fall back to reconstructing from dialogue_id
	var dialogue_id = stage.get(dialogue_key)
	print_debug("[Task] _queue_stage_dialogues: Looking for '%s', found: %s" % [dialogue_key, dialogue_id if dialogue_id else "NONE"])
	if dialogue_id and not String(dialogue_id).is_empty():
		var dialogue_path = _resolve_dialogue_path(String(dialogue_id), stage)
		if not dialogue_path.is_empty():
			if not dialogue_path in _dialogue_queue:
				_dialogue_queue.append(dialogue_path)
				print_debug("[Task] Queued stage %s dialogue: %s -> %s" % [dialogue_type, dialogue_id, dialogue_path])
			else:
				print_debug("[Task] Skipped duplicate: %s" % dialogue_path)
		else:
			print_debug("[Task] Failed to resolve path for: %s" % dialogue_id)
	else:
		print_debug("[Task] No dialogue_id for %s" % dialogue_key)

func _queue_task_dialogues(stage: Resource, dialogue_type: String) -> void:
	"""Queue all task on_enter/on_exit dialogues for a stage."""
	if not stage or not stage.get("active_tasks"):
		print_debug("[Task] _queue_task_dialogues: stage or active_tasks is null/empty")
		return

	var tasks = stage.get("active_tasks") as Array
	print_debug("[Task] _queue_task_dialogues: Processing %d task(s)" % tasks.size())
	for idx in range(tasks.size()):
		var task = tasks[idx]
		if not task:
			print_debug("[Task]   Task %d: null, skipping" % idx)
			continue

		print_debug("[Task]   Task %d ('%s'): processing %s" % [idx, task.get("id") if task.has_method("get") else "unknown", dialogue_type])

		var dialogue_resource_field = ""
		var dialogue_key = ""

		if dialogue_type == "on_enter":
			dialogue_resource_field = "start_dialogue_resource"
			dialogue_key = "enter_dialogue_id"
		elif dialogue_type == "on_exit":
			dialogue_resource_field = "exit_dialogue_resource"
			dialogue_key = "exit_dialogue_id"
		else:
			continue

		# Try to use the pre-built dialogue resource first
		var dialogue_res = task.get(dialogue_resource_field) if task.has_method("get") else ""
		if not String(dialogue_res).is_empty():
			if not dialogue_res in _dialogue_queue:
				_dialogue_queue.append(dialogue_res)
				print_debug("[Task]	→ Queued from %s: %s (queue size now: %d)" % [dialogue_resource_field, dialogue_res.get_file(), _dialogue_queue.size()])
			else:
				print_debug("[Task]	→ Skipped duplicate: %s" % dialogue_res)
			continue

		# Fall back to reconstructing from dialogue_id
		var dialogue_id = task.get(dialogue_key)
		if dialogue_id and not String(dialogue_id).is_empty():
			var dialogue_path = _resolve_dialogue_path(String(dialogue_id), stage)
			if not dialogue_path.is_empty():
				if not dialogue_path in _dialogue_queue:
					_dialogue_queue.append(dialogue_path)
					print_debug("[Task]	→ Queued from ID: %s -> %s (queue size now: %d)" % [dialogue_id, dialogue_path.get_file(), _dialogue_queue.size()])
				else:
					print_debug("[Task]	→ Skipped duplicate: %s" % dialogue_path)

func _resolve_dialogue_path(dialogue_id: String, stage: Stage) -> String:
	"""Resolve a dialogue ID to a resource path."""
	# Extract level prefix from services.level
	var level_prefix = ""

	if _state and _state.level:
		var resource_path = _state.level.resource_path

		# Try direct property access first (works with any Resource)
		if _state.level.has_method("get"):
			var level_id = _state.level.get("level_id")
			if level_id and not String(level_id).is_empty():
				level_prefix = String(level_id)

		# Fall back to direct extraction from path if property failed
		if level_prefix.is_empty() and not resource_path.is_empty():
			level_prefix = resource_path.get_file().trim_suffix(".tres")

	# If no level prefix yet, try to extract from stage resource path
	if level_prefix.is_empty() and stage:
		var stage_path = stage.resource_path
		if not stage_path.is_empty():
			var stage_file = stage_path.get_file().trim_suffix(".tres")
			var regex = RegEx.new()
			regex.compile("^(.+?)_[a-z]+_\\d+$")
			var result = regex.search(stage_file)
			if result:
				level_prefix = result.get_string(1)
			else:
				var last_underscore = stage_file.rfind("_")
				if last_underscore != -1:
					var remainder = stage_file.substr(last_underscore + 1)
					if not remainder.is_empty() and remainder.is_valid_int():
						level_prefix = stage_file.substr(0, last_underscore)

	if level_prefix.is_empty():
		# If no level prefix, try to resolve a generic dialogue path
		var path = FilePaths.DynamicPaths.get_dialogue_path(level_prefix, dialogue_id)
		if ResourceLoader.exists(path):
			return path
		return dialogue_id # Fallback if FilePaths can't resolve it either

	# Use FilePaths helper for the new nested structure
	var preferred_path = FilePaths.DynamicPaths.get_dialogue_path(level_prefix, dialogue_id)

	if ResourceLoader.exists(preferred_path):
		return preferred_path

	return ""

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
