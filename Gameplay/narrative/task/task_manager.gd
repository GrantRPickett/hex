class_name TaskManager
extends Node

signal objective_updated(objective: Objective)
signal objective_completed(objective: Objective)
signal objective_failed(objective: Objective)
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

## A helper to avoid passing mixed/variant arguments to search functions.
class TaskSearchContext:
	var coord: Vector2i = GameConstants.INVALID_COORD
	var target_id: String = ""
	var faction: int = GameConstants.INVALID_INDEX
	var target: Target = null
	
	static func from_target(p_target: Target, p_faction: int = GameConstants.INVALID_INDEX) -> TaskSearchContext:
		var ctx = TaskSearchContext.new()
		ctx.target = p_target
		ctx.faction = p_faction
		if p_target:
			ctx.coord = p_target.get_grid_location()
			ctx.target_id = TaskManager.resolve_target_id(p_target)
		return ctx

	static func from_raw(p_coord: Vector2i, p_id: String = "", p_faction: int = GameConstants.INVALID_INDEX) -> TaskSearchContext:
		var ctx = TaskSearchContext.new()
		ctx.coord = p_coord
		ctx.target_id = p_id
		ctx.faction = p_faction
		return ctx

## Centrally resolve an ID from a Target node for task matching.
static func resolve_target_id(target: Target) -> String:
	if not is_instance_valid(target):
		return ""
	
	# Prioritize the unlocalized 'id' property if it exists,
	# as this is what the Task resources use for matching.
	var raw_id = target.get("id")
	if raw_id and not str(raw_id).is_empty():
		return str(raw_id)
		
	if target is Location:
		return target.loc_name
	elif target is Loot:
		return target.loot_name if not target.loot_name.is_empty() else GameConstants.Tasks.KIND_ITEM
	elif target is Unit:
		return target.unit_name
	
	# Fallback to Node name
	return target.name

func setup(state: GameState) -> void:
	_state = state
	_unit_manager = state.unit_manager

	if _unit_manager:
		if not _unit_manager.unit_moved.is_connected(_on_unit_moved):
			_unit_manager.unit_moved.connect(_on_unit_moved)
		if not _unit_manager.unit_added.is_connected(register_unit):
			_unit_manager.unit_added.connect(register_unit)

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
	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskManager] Preparing objective. Clearing all target lookups.")
	_locations.clear()
	_location_lookup.clear()
	_loot_nodes.clear()
	_loot_lookup.clear()
	level = current_level

	if level_objective:
		_active_objective = level_objective.duplicate(true)
		_active_objective.objective_updated.connect(_on_objective_updated)
		_active_objective.objective_completed.connect(_on_objective_completed)
		_active_objective.objective_failed.connect(_on_objective_failed)
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
		unit.interacted.connect(_on_target_interacted)

func register_location(location: Location) -> void:
	if not _locations.has(location):
		_locations.append(location)
	_location_lookup[location.coord] = location
	if not location.interacted.is_connected(_on_target_interacted):
		location.interacted.connect(_on_target_interacted)
	
	if location.has_method("set_task_manager"):
		location.set_task_manager(self)

func _on_loot_added(loot: Loot, _coord: Vector2i) -> void:
	register_loot(loot)

func _on_loot_removed(loot: Loot) -> void:
	var idx: int = _loot_nodes.find(loot)
	if idx != -1:
		_loot_nodes.remove_at(idx)

	if is_instance_valid(loot):
		if loot.interacted.is_connected(_on_target_interacted):
			loot.interacted.disconnect(_on_target_interacted)

		var coord: Vector2i = loot.get_grid_location()
		if _loot_lookup.get(coord) == loot:
			_loot_lookup.erase(coord)

func register_loot(loot_node: Loot) -> void:
	if not _loot_nodes.has(loot_node):
		_loot_nodes.append(loot_node)
	_loot_lookup[loot_node.get_grid_location()] = loot_node
	if not loot_node.interacted.is_connected(_on_target_interacted):
		loot_node.interacted.connect(_on_target_interacted)
	
	if loot_node.has_method("set_task_manager"):
		loot_node.set_task_manager(self)

func get_active_objective() -> Objective:
	return _active_objective

func get_all_locations() -> Array[Location]:
	return _locations.duplicate()

func get_location_at(coord: Vector2i) -> Location:
	return _location_lookup.get(coord)

func get_loot_at(coord: Vector2i) -> Loot:
	return _loot_lookup.get(coord)

func _on_target_interacted(unit: Unit, context: Dictionary, target: Target) -> void:
	if not _active_objective:
		return

	var interaction_type = context.get("type", "")
	var event_type = GameConstants.TaskEvents.INTERACT
	
	match interaction_type:
		GameConstants.Interactions.VISIT: event_type = GameConstants.TaskEvents.VISIT
		GameConstants.Interactions.EXPLORE: event_type = GameConstants.TaskEvents.EXPLORE
		GameConstants.Interactions.LOOT, GameConstants.Interactions.GATHER: event_type = GameConstants.TaskEvents.LOOT
		GameConstants.Interactions.TRAPPED: event_type = GameConstants.TaskEvents.TRAPPED
		GameConstants.Interactions.CONVINCE: event_type = GameConstants.TaskEvents.CONVINCE
		GameConstants.Interactions.ATTACK: event_type = GameConstants.TaskEvents.ATTACK
		GameConstants.Interactions.TALK: event_type = GameConstants.TaskEvents.DIALOGUE_STARTED

	var unit_faction = unit.get_effective_faction() if unit else GameConstants.INVALID_INDEX
	var search_ctx = TaskSearchContext.from_target(target, unit_faction)
	var tasks = get_active_tasks_for_target_ctx(search_ctx)
	
	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskManager] _on_target_interacted: type=%s, event=%s, target_id=%s, tasks=%d" % [interaction_type, event_type, search_ctx.target_id, tasks.size()])

	if tasks.is_empty():
		# Still propagate raw events to the objective even if no specific tasks match right now
		_active_objective.handle_event(event_type, {
			"unit": unit,
			"coord": search_ctx.coord,
			"id": search_ctx.target_id,
			"target": target,
			"context": context
		})
		return

	for task in tasks:
		task.handle_event(event_type, {
			"unit": unit,
			"target": target,
			"coord": search_ctx.coord,
			"id": search_ctx.target_id,
			"interaction_type": interaction_type
		})

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	if _active_objective and _unit_manager:
		var unit: Unit = _unit_manager.get_unit(index)
		if unit:
			_active_objective.handle_event(GameConstants.TaskEvents.MOVE, {
				"unit": unit,
				"coord": coord
			})

func _on_objective_updated(_objective: Objective) -> void:
	objective_updated.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_started.emit(_active_objective.objective_id)
	_check_stage_spawns()

func _on_objective_completed() -> void:
	objective_completed.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_completed.emit(_active_objective.objective_id)

func _on_objective_failed() -> void:
	objective_failed.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_failed.emit(_active_objective.objective_id)

func _check_stage_spawns() -> void:
	if not _active_objective or not _active_objective.current_stage:
		return

	var current_stage = _active_objective.current_stage

	# Handle location spawns if they exist in the stage
	if current_stage.has_method("get_location_spawns"):
		var spawns: Array = current_stage.get_location_spawns()
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
			var unit: Unit = _unit_manager.get_unit(unit_idx) if unit_idx != GameConstants.INVALID_INDEX else _unit_manager.get_selected_unit()
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

func get_task_for_target(target: Target, faction: int = GameConstants.INVALID_INDEX) -> Task:
	if not _active_objective or not _active_objective.current_stage:
		return null

	var tasks = get_active_tasks_for_target(target, faction)
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

	# Handle UI-generated default eliminate tasks
	if task_id.begins_with("default_eliminate_"):
		var owning_faction: int = int(task_id.replace("default_eliminate_", ""))
		_debug_eliminate_faction(
			GameConstants.Faction.ENEMY if owning_faction == GameConstants.Faction.PLAYER
			else GameConstants.Faction.PLAYER
		)
		return

	var task = get_task_by_id(task_id)
	if task:
		GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskManager] Debug completing task: ", task_id)
		task.force_complete(task.owning_faction)

func _debug_eliminate_faction(faction: int) -> void:
	if not _unit_manager: return
	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskManager] Debug eliminating all units of faction: ", faction)
	var units: Array = _unit_manager.get_units_by_faction(faction)
	for unit in units:
		if is_instance_valid(unit) and not unit.is_dead:
			unit.willpower = 0

func get_active_tasks_for_target(target: Target, faction: int = GameConstants.INVALID_INDEX) -> Array[Task]:
	return get_active_tasks_for_target_ctx(TaskSearchContext.from_target(target, faction))

func get_active_tasks_for_target_ctx(ctx: TaskSearchContext) -> Array[Task]:
	var matching_tasks: Array[Task] = []
	if not _active_objective or not _active_objective.current_stage or (ctx.target == null and ctx.coord == GameConstants.INVALID_COORD):
		if ctx.target == null and ctx.coord == GameConstants.INVALID_COORD:
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskManager] get_active_tasks_for_target: No active objective/stage or target/coord is null")
		return matching_tasks

	for task in _active_objective.current_stage.active_tasks:
		if task == null:
			continue

		if task.status != Task.Status.ACTIVE:
			continue

		if ctx.faction != GameConstants.INVALID_INDEX and task.owning_faction != ctx.faction:
			continue

		var matches_coord: bool = (task.target_coord == ctx.coord) if task.target_coord != GameConstants.INVALID_COORD else false
		var matches_id: bool = (task.target_id == ctx.target_id) if not task.target_id.is_empty() else false
		
		if matches_coord or matches_id:
			matching_tasks.append(task)

	return matching_tasks

func _on_task_completed_relay(task: Task, faction: int, unit: Unit) -> void:
	var index: int = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)
	task_completed.emit(index, faction, unit)
	if EventBus and task: EventBus.task_completed.emit(task.id)

func _on_task_failed_relay(task: Task) -> void:
	var index: int = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)
	task_failed.emit(index, 0) # Faction default to 0
	if EventBus and task: EventBus.task_failed.emit(task.id)

func _on_task_updated_relay(task: Task, faction: int) -> void:
	var index: int = -1
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
