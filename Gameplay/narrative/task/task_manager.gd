class_name TaskManager
extends Node

signal objective_updated(objective: Objective)
signal objective_completed(objective: Objective)
signal objective_failed(objective: Objective)
signal stage_completed(next_stage: Stage, completing_stage: Stage)
signal task_completed(index: int, faction: int, unit: Unit)
signal task_failed(index: int, faction: int)
signal task_updated(index: int, faction: int)

var _active_objective: Objective
var _locations: Array[Location] = []
var _loot_nodes: Array[Loot] = []
var _location_lookup: Dictionary = {}
var _loot_lookup: Dictionary = {}

# O(1) lookups by ID
var _task_lookup: Dictionary = {} # task_id -> Task

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

	var tid = target.get_target_id() if target.has_method("get_target_id") else ""
	if not tid.is_empty():
		return tid

	var tname = target.get_target_name() if target.has_method("get_target_name") else str(target.name)
	return tname

func setup(state: GameState) -> void:
	_state = state
	_unit_manager = state.unit_manager

	if _unit_manager:
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
	GameLogger.debug(GameLogger.Category.TASK, "[TaskManager] Preparing objective. Clearing all target lookups.")
	_location_lookup.clear()
	_loot_nodes.clear()
	_loot_lookup.clear()
	_task_lookup.clear()
	level = current_level

	if level_objective:
		_active_objective = level_objective.duplicate(true)
		_active_objective.objective_updated.connect(_on_objective_updated)
		_active_objective.objective_completed.connect(_on_objective_completed)
		_active_objective.objective_failed.connect(_on_objective_failed)
		if _active_objective.has_signal("stage_completed"):
			_active_objective.stage_completed.connect(_on_stage_completed_relay)
		if _active_objective.has_signal("task_completed"):
			_active_objective.task_completed.connect(_on_task_completed_relay)
		if _active_objective.has_signal("task_failed"):
			_active_objective.task_failed.connect(_on_task_failed_relay)
		if _active_objective.has_signal("task_updated"):
			_active_objective.task_updated.connect(_on_task_updated_relay)

		# Build initial task lookup
		if _active_objective.current_stage:
			for task in _active_objective.current_stage.active_tasks:
				if task: _task_lookup[str(task.id)] = task
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
	if not is_instance_valid(unit): return
	if not unit.interacted.is_connected(_on_target_interacted):
		unit.interacted.connect(_on_target_interacted)
func register_location(location: Location) -> void:
	if not _locations.has(location):
		_locations.append(location)
	_location_lookup[location.coord] = location
	if not location.interacted.is_connected(_on_target_interacted):
		location.interacted.connect(_on_target_interacted)

	if location.has_method("set_task_manager"):
		location.set_task_manager(self )

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
		loot_node.set_task_manager(self )

func get_active_objective() -> Objective:
	return _active_objective

func get_all_locations() -> Array[Location]:
	return _locations.duplicate()

func get_location_at(coord: Vector2i) -> Location:
	return _location_lookup.get(coord)

func get_loot_at(coord: Vector2i) -> Loot:
	return _loot_lookup.get(coord)

## Returns all targets at a coord. Delegates to TargetDiscoveryService.
func get_targets_at(coord: Vector2i) -> Array[Target]:
	return TargetDiscoveryService.get_targets_at_coord(coord, {"task_manager": self, "unit_manager": _unit_manager})

## Typed: returns the target at a coord matching a script class name (e.g. &"Location").
func get_typed_target_at(coord: Vector2i, type_name: StringName) -> Target:
	return TargetDiscoveryService.get_typed_target_at_coord(coord, {"task_manager": self, "unit_manager": _unit_manager}, type_name)

## Convenience: returns the first target at a coord, or null.
func get_target_at(coord: Vector2i) -> Target:
	return TargetDiscoveryService.get_target_at_coord(coord, {"task_manager": self, "unit_manager": _unit_manager})

func get_target_by_id(target_id: String) -> Target:
	if target_id.is_empty(): return null
	return TargetDiscoveryService.get_target_by_id(target_id)

func get_unit(index: int) -> Unit:
	if _unit_manager:
		return _unit_manager.get_unit(index)
	return null

## Returns all active tasks for the current stage, optionally filtered by faction.
func get_active_tasks(faction: int = GameConstants.INVALID_INDEX) -> Array[Task]:
	var tasks: Array[Task] = []
	if not _active_objective or not _active_objective.current_stage:
		return tasks
	for task in _active_objective.current_stage.active_tasks:
		if is_instance_valid(task) and task.status == Task.Status.ACTIVE:
			if faction == GameConstants.INVALID_INDEX or task.owning_faction == faction:
				tasks.append(task)
	return tasks

## Returns tasks immediately actionable at a coordinate for a unit.
func get_immediate_tasks(unit: Unit, coord: Vector2i) -> Array[Task]:
	var faction: int = unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX
	var immediate: Array[Task] = []
	var relevant_types := [
		GameConstants.Activity.EXPLORE, GameConstants.Activity.VISIT,
		GameConstants.Activity.GATHER, GameConstants.Activity.TRAPPED,
		GameConstants.Activity.INTERACT
	]
	for task in get_active_tasks(faction):
		if task.event_type not in relevant_types:
			continue
		var target_id := ""
		var target = get_target_at(coord)
		if target:
			target_id = resolve_target_id(target)
		var matches := (task.target_coord != GameConstants.INVALID_COORD and task.target_coord == coord) or \
			(not task.target_id.is_empty() and not target_id.is_empty() and task.target_id == target_id)
		if matches and is_instance_valid(unit) and task.can_be_worked_on_by(unit, coord):
			immediate.append(task)
	return immediate

## Categorizes location tasks into immediate/reachable × explore/visit.
func get_categorized_location_tasks(unit: Unit, action_origin: Vector2i, reachable_lookup: Dictionary) -> Dictionary:
	var result := {
		"immediate_explore": [] as Array[Task],
		"immediate_visit": [] as Array[Task],
		"reachable_explore": [] as Array[Task],
		"reachable_visit": [] as Array[Task]
	}
	var faction: int = unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX
	for task in get_active_tasks(faction):
		if task.target_kind != GameConstants.Activity.KIND_LOCATION:
			continue
		var target_coord: Vector2i = task.target_coord
		if target_coord == GameConstants.INVALID_COORD and not task.target_id.is_empty():
			var targ := get_target_by_id(task.target_id)
			if is_instance_valid(targ):
				target_coord = targ.get_grid_location()
		if target_coord == GameConstants.INVALID_COORD:
			continue
		var loc := get_location_at(target_coord)
		if loc == null:
			continue
		if not task.target_id.is_empty() and resolve_target_id(loc) != task.target_id:
			continue
		var is_opposed: bool = (task.event_type == GameConstants.Activity.EXPLORE or
			task.event_type == GameConstants.Activity.INTERACT or task.is_opposed)
		if is_opposed and loc.willpower <= 0:
			is_opposed = false
		if target_coord == action_origin:
			result["immediate_explore" if is_opposed else "immediate_visit"].append(task)
		elif reachable_lookup.has(target_coord):
			result["reachable_explore" if is_opposed else "reachable_visit"].append(task)
	return result

## Builds a target→task_id mapping for a list of targets.
func build_target_to_task(targets: Array, faction: int) -> Dictionary:
	var result := {}
	var active := get_active_tasks(faction)
	for target in targets:
		if not is_instance_valid(target): continue
		var targ := target as Target
		if not targ: continue
		var tid := resolve_target_id(targ)
		var coord: Vector2i = targ.get_grid_location()
		for t in active:
			if (not t.target_id.is_empty() and t.target_id == tid) or \
				(t.target_coord != GameConstants.INVALID_COORD and t.target_coord == coord):
				result[target] = t.id
				break
	return result


func _on_target_interacted(unit: Unit, context: CombatResult, target: Target) -> void:
	if not _active_objective:
		return

	var interaction_type: String = context.type
	var event_type = GameConstants.get_task_event_for_interaction(interaction_type)

	var unit_faction = unit.get_effective_faction() if unit else GameConstants.INVALID_INDEX
	var search_ctx = TaskSearchContext.from_target(target, unit_faction)
	var tasks = get_active_tasks_for_target_ctx(search_ctx)

	GameLogger.debug(GameLogger.Category.TASK, "[TaskManager] _on_target_interacted: type=%s, event=%s, target_id=%s, tasks=%d" % [interaction_type, event_type, search_ctx.target_id, tasks.size()])

	for task in tasks:
		task.handle_event(event_type, context)

		# Notify the HUD so world-driven progress bars (showing target willpower) refresh.
		if _active_objective and _active_objective.current_stage:
			var index: int = _active_objective.current_stage.active_tasks.find(task)
			task_updated.emit(index, task.owning_faction)

func _on_objective_updated(_objective: Objective) -> void:
	objective_updated.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_started.emit(_active_objective.objective_id)

func _on_objective_completed() -> void:
	objective_completed.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_completed.emit(_active_objective.objective_id)

func _on_objective_failed() -> void:
	objective_failed.emit(_active_objective)
	if EventBus and _active_objective: EventBus.objective_failed.emit(_active_objective.objective_id)

func _on_game_action(action: Dictionary) -> void:
	if _active_objective == null:
		return

	var cmd: StringName = action.get(GameConstants.Payload.COMMAND, &"")
	var payload = action.get(GameConstants.Payload.PAYLOAD)

	if not payload is Dictionary:
		return

	match cmd:
		#GameConstants.Commands.SKILL:
			#var unit_idx = payload.get(GameConstants.Payload.UNIT_INDEX, GameConstants.INVALID_INDEX)
			#var unit: Unit = _unit_manager.get_unit(unit_idx) if unit_idx != GameConstants.INVALID_INDEX else _unit_manager.get_selected_unit()
			#var skill = payload.get(GameConstants.Payload.SKILL)
			#if unit and skill:
				#_active_objective.handle_event(GameConstants.Activity.ABILITY_USED, {
					#"unit": unit,
					#"id": skill.skill_name,
					#"skill": skill
				#})
#
		#GameConstants.Commands.TRIGGER_DIALOGUE:
			#_active_objective.handle_event(GameConstants.Activity.DIALOGUE_STARTED, {
				#"id": payload.get(GameConstants.Payload.DIALOGUE_ID, ""),
				#"path": payload.get(GameConstants.Payload.DIALOGUE_RESOURCE_PATH, "")
			#})

		_:
			# All other world-targeted commands (gather, ATTACK, CONVINCE, VISIT, EXPLORE)
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
	if task_id.is_empty(): return null
	return _task_lookup.get(str(task_id))

func debug_complete_task(task_id: String) -> void:
	if not OS.is_debug_build():
		return

	var s_id := str(task_id)
	# Handle UI-generated default eliminate tasks
	if s_id.begins_with("default_eliminate_"):
		var owning_faction: int = int(task_id.replace("default_eliminate_", ""))
		_debug_eliminate_faction(
			GameConstants.Faction.ENEMY if owning_faction == GameConstants.Faction.PLAYER
			else GameConstants.Faction.PLAYER
		)
		return

	var task = get_task_by_id(task_id)
	if task:
		GameLogger.debug(GameLogger.Category.TASK, "[TaskManager] Debug completing task: ", task_id)

		# If the task has a target, we should ensure the target's visual state is updated
		if not task.target_id.is_empty():
			var target = get_target_by_id(task.target_id)
			if target is Loot:
				target.disarm_trap()

		task.force_complete(task.owning_faction)

func _debug_eliminate_faction(faction: int) -> void:
	if not _unit_manager: return
	GameLogger.debug(GameLogger.Category.TASK, "[TaskManager] Debug eliminating all units of faction: ", faction)
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
			GameLogger.debug(GameLogger.Category.TASK, "[TaskManager] get_active_tasks_for_target: No active objective/stage or target/coord is null")
		return matching_tasks

	var event_data = {
		"target": ctx.target,
		"coord": ctx.coord,
		"id": ctx.target_id
	}

	for task in _active_objective.current_stage.active_tasks:
		if task == null:
			continue

		if task.status != Task.Status.ACTIVE:
			continue

		if ctx.faction != GameConstants.INVALID_INDEX and task.owning_faction != ctx.faction:
			continue

		if TaskProcessor.validate_interaction_data(task, "", event_data):
			matching_tasks.append(task)

	return matching_tasks

func get_processed_tasks_data() -> Array:
	if not _active_objective or not _active_objective.current_stage:
		return []

	var stage = _active_objective.current_stage
	var factions = [GameConstants.Faction.PLAYER, GameConstants.Faction.ENEMY, GameConstants.Faction.NEUTRAL]
	var processed_data = []

	for faction in factions:
		var faction_tasks = _collect_tasks_for_faction(stage, faction)

		# Inject default eliminate if missing but units exist
		if faction_tasks.is_empty():
			var default_task = _get_default_eliminate_task(faction)
			if not default_task.is_empty():
				faction_tasks.append(default_task)

		if not faction_tasks.is_empty():
			processed_data.append({
				"faction": faction,
				"tasks": faction_tasks
			})

	return processed_data

func _collect_tasks_for_faction(p_stage: Resource, faction: int) -> Array:
	var tasks = []
	if p_stage and p_stage.get("active_tasks"):
		for task in p_stage.active_tasks:
			if task.owning_faction == faction:
				tasks.append(task)
	return tasks

func _get_default_eliminate_task(faction: int) -> Dictionary:
	if not _unit_manager:
		return {}

	var units: Array = _unit_manager.get_units_by_faction(faction)
	if units.is_empty():
		return {}

	if faction == GameConstants.Faction.ENEMY:
		var player_units = _unit_manager.get_player_units()
		var total = player_units.size()
		var alive = 0
		for u in player_units:
			if is_instance_valid(u) and u.willpower > 0:
				alive += 1

		return {
			"id": "default_eliminate_" + str(faction),
			"title": TranslationServer.translate("hud.task.default_eliminate_title"),
			"description": TranslationServer.translate("hud.task.default_eliminate_desc"),
			"status": TranslationServer.translate("hud.task.status_active"),
			"completed": false,
			"current": total - alive,
			"required": total,
			"is_default": true
		}
	return {}

func _on_task_completed_relay(task: Task, faction: int, unit: Unit) -> void:
	var index: int = -1
	if _active_objective and _active_objective.current_stage:
		index = _active_objective.current_stage.active_tasks.find(task)

	# Pacing buffer for action barks (UI only)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.8).timeout

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

func _on_stage_completed_relay(next_stage: Stage, completing_stage: Stage) -> void:
	# Pacing buffer for action barks (UI only)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.8).timeout

	stage_completed.emit(next_stage, completing_stage)
	if EventBus and completing_stage:
		EventBus.stage_completed.emit(str(completing_stage.id))

func create_memento() -> Dictionary:
	var memento = {
		"objective": _active_objective.create_memento() if _active_objective else {}
	}
	return memento

func restore_from_memento(memento: Dictionary) -> void:
	if memento.has("objective") and _active_objective:
		_active_objective.restore_from_memento(memento["objective"])
