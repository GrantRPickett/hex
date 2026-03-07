class_name TaskManager
extends Node

signal objective_updated(objective: Objective)
signal objective_completed(objective: Objective)
signal task_completed(index: int, faction: int, unit: Unit)
signal task_failed(index: int, faction: int)
signal task_updated(index: int, faction: int)

var _active_objective: Objective
var _locations: Array[Location] = []
var _loot_nodes: Array[Loot] = []
var _location_lookup: Dictionary = {}
var _loot_lookup: Dictionary = {}
var _unit_manager: UnitManager
var level: Level
var _state: GameState

func setup(state: GameState) -> void:
	_state = state
	_unit_manager = state.unit_manager

	if _unit_manager:
		if not _unit_manager.unit_moved.is_connected(_on_unit_moved):
			_unit_manager.unit_moved.connect(_on_unit_moved)
		if not _unit_manager.unit_spawn_requested.is_connected(register_unit):
			_unit_manager.unit_spawn_requested.connect(register_unit)

		# Register existing units
		for unit in _unit_manager.get_all_units():
			register_unit(unit)

	# Listen for normalized game actions from the command router to evaluate tasks
	# Only for actions that don't have a specific Target in the world.
	if _state and _state.command_router and not _state.command_router.game_action.is_connected(_on_game_action):
		_state.command_router.game_action.connect(_on_game_action)

	if _state and _state.loot_manager:
		if not _state.loot_manager.loot_added.is_connected(_on_loot_added):
			_state.loot_manager.loot_added.connect(_on_loot_added)
		if not _state.loot_manager.loot_removed.is_connected(_on_loot_removed):
			_state.loot_manager.loot_removed.connect(_on_loot_removed)


func prepare_objective(current_level: Level, level_objective: Objective) -> void:
	_locations.clear()
	_location_lookup.clear()
	level = current_level

	if level_objective:
		_active_objective = level_objective.duplicate(true)
		_active_objective.objective_updated.connect(_on_objective_updated)
		_active_objective.objective_completed.connect(_on_objective_completed)
		if _active_objective.has_signal("task_completed"):
			_active_objective.task_completed.connect(_on_task_completed_relay)
		if _active_objective.has_signal("task_failed"):
			_active_objective.task_failed.connect(_on_task_failed_relay)
		if _active_objective.has_signal("task_updated"):
			_active_objective.task_updated.connect(_on_task_updated_relay)
	else:
		_active_objective = null

func start_active_objective() -> void:
	if _active_objective and level:
		_active_objective.start_objective(level)

# --- Legacy Helper ---

func set_level_and_objective(current_level: Level, level_objective: Objective) -> void:
	prepare_objective(current_level, level_objective)
	start_active_objective()

func register_unit(unit: Unit) -> void:
	if not unit.interacted.is_connected(_on_target_interacted):
		unit.interacted.connect(_on_target_interacted.bind(unit))

func register_location(location: Location) -> void:
	if not _locations.has(location):
		_locations.append(location)
	_location_lookup[location.coord] = location
	if not location.interacted.is_connected(_on_target_interacted):
		location.interacted.connect(_on_target_interacted.bind(location))

func _on_loot_added(loot: Loot, _coord: Vector2i) -> void:
	register_loot(loot)

func _on_loot_removed(loot: Loot) -> void:
	var idx = _loot_nodes.find(loot)
	if idx != -1:
		_loot_nodes.remove_at(idx)

	if is_instance_valid(loot):
		if loot.interacted.is_connected(_on_target_interacted):
			loot.interacted.disconnect(_on_target_interacted)

		var coord = loot.get_grid_location()
		if _loot_lookup.get(coord) == loot:
			_loot_lookup.erase(coord)

func register_loot(loot_node: Loot) -> void:
	if not _loot_nodes.has(loot_node):
		_loot_nodes.append(loot_node)
	_loot_lookup[loot_node.get_grid_location()] = loot_node
	if not loot_node.interacted.is_connected(_on_target_interacted):
		loot_node.interacted.connect(_on_target_interacted.bind(loot_node))

func get_active_objective() -> Objective:
	return _active_objective

func get_location_at(coord: Vector2i) -> Location:
	return _location_lookup.get(coord)

func get_loot_at(coord: Vector2i) -> Loot:
	return _loot_lookup.get(coord)

func _on_target_interacted(unit: Unit, context: Dictionary, target: Target) -> void:
	if not _active_objective:
		return

	var interaction_type = context.get("type", "")
	var event_type = GameConstants.TaskEvents.TARGET_INTERACTION
	var target_id = ""

	match interaction_type:
		GameConstants.Interactions.VISIT:
			event_type = GameConstants.TaskEvents.VISIT
			if target is Location: target_id = target.loc_name
		GameConstants.Interactions.EXPLORE:
			event_type = GameConstants.TaskEvents.EXPLORE
			if target is Location: target_id = target.loc_name
		GameConstants.Interactions.LOOT:
			event_type = GameConstants.TaskEvents.LOOT
			target_id = GameConstants.Tasks.KIND_ITEM
		GameConstants.Interactions.TRAPPED:
			event_type = GameConstants.TaskEvents.TRAPPED
			target_id = "trapped"
		GameConstants.Interactions.CONVINCE:
			event_type = GameConstants.TaskEvents.CONVINCE
			target_id = "convince"
		GameConstants.Interactions.ATTACK:
			event_type = GameConstants.TaskEvents.ATTACK
			if target is Unit: target_id = target.unit_name
		GameConstants.Interactions.TALK:
			event_type = GameConstants.TaskEvents.DIALOGUE_STARTED
			if target is Unit: target_id = target.unit_name
		_:
			# Fallback for old style or missing type
			if target is Location:
				target_id = target.loc_name
			elif target is Loot:
				target_id = GameConstants.Tasks.KIND_ITEM
				event_type = GameConstants.TaskEvents.PICKUP

	var tasks = get_active_tasks_for_target(target)
	print_debug("[TaskManager] _on_target_interacted: type=%s, event=%s, tasks=%d" % [interaction_type, event_type, tasks.size()])

	_active_objective.handle_event(event_type, {
		"unit": unit,
		"coord": target.get_grid_location(),
		"id": target_id,
		"target": target,
		"context": context
	})

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	if _active_objective and _unit_manager:
		var unit = _unit_manager.get_unit(index)
		if unit:
			_active_objective.handle_event(GameConstants.TaskEvents.MOVE, {
				"unit": unit,
				"coord": coord
			})

func _on_objective_updated(_objective: Objective) -> void:
	objective_updated.emit(_active_objective)
	_check_stage_spawns()

func _on_objective_completed() -> void:
	objective_completed.emit(_active_objective)

func _check_stage_spawns() -> void:
	if not _active_objective or not _active_objective.current_stage:
		return

	var current_stage = _active_objective.current_stage

	# Handle location spawns if they exist in the stage
	if current_stage.has_method("get_location_spawns"):
		var spawns = current_stage.get_location_spawns()
		for spawn in spawns:
			_spawn_location(spawn)

func _spawn_location(_spawn_data: Dictionary) -> void:
	# Implementation for spawning dynamic locations from stage data
	pass

func _on_game_action(action: Dictionary) -> void:
	if _active_objective == null:
		return

	var cmd: StringName = action.get(GameConstants.Payload.COMMAND, &"")
	var payload = action.get(GameConstants.Payload.PAYLOAD)

	if not payload is Dictionary:
		return

	match cmd:
		GameConstants.Commands.USE_SKILL:
			var unit_idx = payload.get(GameConstants.Payload.UNIT_INDEX, GameConstants.INVALID_INDEX)
			var unit = _unit_manager.get_unit(unit_idx) if unit_idx != GameConstants.INVALID_INDEX else _unit_manager.get_selected_unit()
			var skill = payload.get(GameConstants.Payload.SKILL)
			if unit and skill:
				_active_objective.handle_event(GameConstants.TaskEvents.ABILITY_USED, {
					"unit": unit,
					"id": skill.skill_name,
					"skill": skill
				})

		GameConstants.Commands.TRIGGER_DIALOGUE:
			_active_objective.handle_event(GameConstants.TaskEvents.DIALOGUE_STARTED, {
				"id": payload.get(GameConstants.Payload.DIALOGUE_ID, ""),
				"path": payload.get(GameConstants.Payload.DIALOGUE_RESOURCE_PATH, "")
			})

		_:
			# All other world-targeted commands (LOOT, ATTACK, CONVINCE, TALK, VISIT, EXPLORE)
			# are handled via Target.interacted signal from TargetInteractionHandler.
			pass

func get_task_for_target(target: Target) -> Task:
	if not _active_objective or not _active_objective.current_stage:
		return null

	var tasks = get_active_tasks_for_target(target)
	if not tasks.is_empty():
		return tasks[0]
	return null

func get_task_by_id(task_id: String) -> Task:
	if not _active_objective or not _active_objective.current_stage:
		return null

	for task in _active_objective.current_stage.active_tasks:
		if task == null:
			continue
		if String(task.id) == task_id:
			return task
	return null

func debug_complete_task(task_id: String) -> void:
	if not OS.is_debug_build():
		return
		
	var task = get_task_by_id(task_id)
	if task:
		print_debug("[TaskManager] Debug completing task: ", task_id)
		task.force_complete(task.owning_faction)

func get_active_tasks_for_target(target: Target) -> Array[Task]:
	var matching_tasks: Array[Task] = []
	if not _active_objective or not _active_objective.current_stage or target == null:
		return matching_tasks

	var coord = target.get_grid_location()
	var target_id = ""
	if target is Location:
		target_id = target.loc_name
	elif target is Loot:
		target_id = GameConstants.Tasks.KIND_ITEM
	elif target is Unit:
		target_id = target.unit_name

	for task in _active_objective.current_stage.active_tasks:
		if task == null or task.status != Task.Status.ACTIVE:
			continue

		var matches_coord = false
		if task.target_coord != GameConstants.INVALID_COORD:
			matches_coord = (task.target_coord == coord)

		var matches_id = false
		if not task.target_id.is_empty():
			matches_id = (task.target_id == target_id)

		if matches_coord or matches_id:
			matching_tasks.append(task)

	return matching_tasks

func _on_task_completed_relay(task: Task, faction: int, unit: Unit) -> void:
	var index = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)
	task_completed.emit(index, faction, unit)

func _on_task_failed_relay(task: Task) -> void:
	var index = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)
	task_failed.emit(index, 0) # Faction default to 0

func _on_task_updated_relay(task: Task, faction: int) -> void:
	var index = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)
	task_updated.emit(index, faction)

func create_memento() -> Dictionary:
	var memento = {
		"objective": _active_objective.create_memento() if _active_objective else {}
	}
	return memento

func restore_from_memento(memento: Dictionary) -> void:
	if memento.has("objective") and _active_objective:
		_active_objective.restore_from_memento(memento["objective"])
