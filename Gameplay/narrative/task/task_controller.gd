class_name TaskController
extends Node
signal task_reached
signal game_over
signal dialogue_requested(dialogue_resource_path: String)

var _task_manager: TaskManager
var _unit_manager: UnitManager
var _unit_controller: UnitController
var _turn_controller: TurnController
var _loot_manager: LootManager
var _combat_system: CombatSystem
var _location_service: LocationService
var _state: GameState
var _task_reached_state: bool = false
var _game_over_state: bool = false

var _dialogue_handler # Type: TaskDialogueHandler
var _condition_handler # Type: TaskConditionHandler
var _current_stage_id: StringName = &""
var level: Level

func setup(state: GameState) -> void:
	print_debug("[Task] setup() called with state=%s" % ["valid" if state else "null"])
	_task_manager = state.task_manager
	_unit_manager = state.unit_manager
	_unit_controller = state.unit_controller
	_turn_controller = state.turn_controller
	_loot_manager = state.loot_manager
	_combat_system = state.combat_system
	_location_service = state.location_service
	_state = state
	_dialogue_handler = load("res://Gameplay/narrative/task/task_dialogue_handler.gd").new()
	_condition_handler = load("res://Gameplay/narrative/task/task_condition_handler.gd").new()
	_dialogue_handler.dialogue_requested.connect(func(path): dialogue_requested.emit(path))
	_dialogue_handler.setup(state)
	_condition_handler.setup(_task_manager, _unit_manager)

	if _task_manager:
		print_debug("[Task] Connecting to task_manager signals")
		if not _task_manager.task_completed.is_connected(on_task_completed):
			_task_manager.task_completed.connect(on_task_completed)
		if not _task_manager.objective_updated.is_connected(_on_objective_updated):
			_task_manager.objective_updated.connect(_on_objective_updated)

		var active_obj = _task_manager.get_active_objective()
		if active_obj and active_obj.is_active and active_obj.current_stage:
			print_debug("[Task] Objective already active during setup")

	if _turn_controller and not _turn_controller.round_changed.is_connected(on_round_changed):
		_turn_controller.round_changed.connect(on_round_changed)

func set_level(current_level: Level) -> void:
	print_debug("[Task] set_level called with current_level=%s" % [current_level.resource_path if current_level else "null"])
	self.level = current_level
	if _task_manager:
		_task_manager.set_level_and_objective(current_level, current_level.objective)

func on_unit_defeated(unit: Unit) -> void:
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj:
			obj.handle_event("unit_defeated", {"unit": unit})
	check_objective_conditions()

func _on_stage_completed(_next_stage: Stage, completing_stage: Stage) -> void:
	if completing_stage:
		print_debug("[Task] Stage '%s' completed, queuing exit dialogues..." % completing_stage.id)
		_dialogue_handler.queue_task_dialogues(completing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(completing_stage, "on_exit")
		_current_stage_id = &""
		_dialogue_handler.process_queue()

func _on_stage_failed(failing_stage: Stage) -> void:
	if failing_stage:
		print_debug("[Task] Stage '%s' failed, queuing exit dialogues..." % failing_stage.id)
		_dialogue_handler.queue_task_dialogues(failing_stage, "on_exit")
		_dialogue_handler.queue_stage_dialogues(failing_stage, "on_exit")
		_dialogue_handler.process_queue()

func on_task_completed(_index: int, _faction: int) -> void:
	check_objective_conditions()

func _on_objective_updated(objective: Resource) -> void:
	if objective and objective.is_active and objective.current_stage:
		var stage = objective.current_stage
		var stage_id = stage.get("id") if stage.has_method("get") else &""

		if stage_id == _current_stage_id:
			return

		_current_stage_id = stage_id
		_log_stage_transition(objective)

		if not stage.stage_completed.is_connected(_on_stage_completed):
			stage.stage_completed.connect(_on_stage_completed.bindv([stage]))
		if not stage.stage_failed.is_connected(_on_stage_failed):
			stage.stage_failed.connect(_on_stage_failed.bindv([stage]))

		_dialogue_handler.queue_stage_dialogues(stage, "on_enter")
		_dialogue_handler.queue_task_dialogues(stage, "on_enter")
		_handle_stage_spawns(stage)
		_dialogue_handler.process_queue()
	check_objective_conditions()

func on_round_changed(current_round: int) -> void:
	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj: obj.handle_event("round_changed", {"round": current_round})
	check_objective_conditions()

func check_objective_conditions() -> void:
	if _task_reached_state or _game_over_state:
		return

	var player_units = _condition_handler.get_player_units()
	check_inventory_objectives(player_units)

	if _task_manager:
		var obj = _task_manager.get_active_objective()
		if obj and obj.is_active and obj.current_stage:
			# Check special completion conditions for active tasks
			for task in obj.current_stage.active_tasks:
				if not is_instance_valid(task) or task.status != Task.Status.ACTIVE:
					continue

				if task.completion_condition and task.completion_condition.type == "DEFEAT_ALL_UNITS_OF_FACTION":
					var target_faction = task.completion_condition.faction
					var units_alive = _unit_manager.get_units_by_faction(target_faction) if _unit_manager.has_method("get_units_by_faction") else []
					if units_alive.is_empty():
						task.force_complete()


		if obj:
			if not obj.is_active:
				_log_objective_completed(obj)
				_task_reached_state = true
				_grant_end_of_level_rewards()
				task_reached.emit()
			elif _condition_handler.check_objective_failed(obj):
				_log_objective_failed(obj)
				_game_over_state = true
				game_over.emit()

func _grant_end_of_level_rewards() -> void:
	if not _loot_manager or not _unit_manager or not _state.player_roster:
		return

	var collected_items: Array[InventoryItem] = []

	# 1. Collect from routing pool (difficulty-based missed loot)
	if _loot_manager.has_method("collect_routing_pool"):
		collected_items.append_array(_loot_manager.collect_routing_pool())

	# 2. Collect from ground loot (Standard behavior for "map routing")
	collected_items.append_array(_loot_manager.collect_all_loot_items())

	# 3. Collect from surviving neutrals (Spec requirement)
	var neutrals = _unit_manager.get_neutral_units()
	for unit in neutrals:
		if is_instance_valid(unit) and unit.willpower > 0:
			var inv_comp = unit.inv
			if inv_comp:
				var inv_ref = inv_comp.get_inventory()
				if inv_ref:
					collected_items.append_array(inv_ref.get_items())
					inv_ref.clear()

	# 4. Add to player stash
	_state.player_roster.add_to_stash(collected_items)
	print_debug("[Task] End of level rewards granted: %d items added to stash" % collected_items.size())

func check_inventory_objectives(player_units: Array[Unit]) -> void:
	if _task_manager:
		_condition_handler.handle_inventory_check(_task_manager.get_active_objective(), player_units)

func _handle_stage_spawns(stage: Resource) -> void:
	if not _unit_manager or not _state.map_controller:
		return

	var spawn_occurred := false
	var grid = _state.map_controller.get_grid()
	var all_spawns: Array = []

	for field in ["enemy_spawns", "neutral_spawns", "spawns"]:
		var spawns = stage.get(field) if stage.has_method("get") else []
		if not spawns.is_empty(): all_spawns.append_array(spawns)

	for spawn in all_spawns:
		if not spawn: continue
		var unit = TargetSpawner.spawn_unit(spawn, _unit_manager, _loot_manager, _task_manager, _location_service, _combat_system, grid)
		if unit: spawn_occurred = true

	if spawn_occurred and _turn_controller:
		_turn_controller.rebuild_turn_roster()

func is_task_reached() -> bool: return _task_reached_state

func reset_task_state() -> void:
	_task_reached_state = false
	_game_over_state = false

func create_memento() -> Dictionary:
	return _task_manager.create_memento() if _task_manager else {}

func restore_from_memento(memento: Dictionary) -> void:
	if _task_manager: _task_manager.restore_from_memento(memento)

func get_task_by_id(task_id: String) -> Task:
	if not _task_manager: return null
	return _task_manager.get_task_by_id(task_id)

func get_task_info(task_id: String) -> Dictionary:
	if not _task_manager: return {}
	var task = _task_manager.get_task_by_id(task_id)
	return _transform_task_to_info(task) if task else {}

func get_task_at_coord(coord: Vector2i) -> Dictionary:
	if not _task_manager: return {}
	var location = _task_manager.get_location_at(coord)
	var tasks: Array[Task] = []
	if location: tasks = _task_manager.get_active_tasks_for_target(location)
	if tasks.is_empty():
		var loot = _task_manager.get_loot_at(coord)
		if loot: tasks = _task_manager.get_active_tasks_for_target(loot)
	return _transform_task_to_info(tasks[0]) if not tasks.is_empty() else {}

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
	if not objective or not objective.current_stage: return
	var stage = objective.current_stage
	var completed_count = stage.active_tasks.filter(func(t): return t.status == Task.Status.COMPLETED).size()
	print_debug("[Task] Stage transitioned: '%s' | Tasks: %d/%d completed" % [stage.id, completed_count, stage.active_tasks.size()])

func _log_objective_completed(objective: Resource) -> void:
	if objective: print_debug("[Task] OBJECTIVE COMPLETED: '%s'" % objective.title)

func _log_objective_failed(objective: Resource) -> void:
	if objective: print_debug("[Task] OBJECTIVE FAILED: '%s'" % objective.title)

func _on_dialogue_finished(_flag: StringName = &"") -> void:
	_dialogue_handler.on_dialogue_finished()
