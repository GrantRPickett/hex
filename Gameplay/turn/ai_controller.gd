class_name AIController
extends Node

## Orchestrates AI turn execution.

# ---------------------------------------------------------------------------
# Dependencies (injected by GameSessionBuilder / setup())
# ---------------------------------------------------------------------------
var _unit_manager: UnitManager
var _map_controller: MapController
var _task_manager: TaskManager
var _loot_manager: LootManager
var _turn_controller: TurnController
var _command_context: GameCommandContext
var _router: InputCommandRouter

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
var _evaluators: Array[AIActionEvaluator] = []
var _current_ai_modifier: float = 0.0
var _initial_max_willpower: Dictionary = {
	GameConstants.Faction.PLAYER: 0,
	GameConstants.Faction.ENEMY: 0,
	GameConstants.Faction.NEUTRAL: 0
}

@onready var _weather_manager = get_node_or_null("/root/WeatherManager")

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	if is_instance_valid(_weather_manager):
		_weather_manager.weather_effect_applied.connect(_on_weather_effect_applied)

func _exit_tree() -> void:
	if is_instance_valid(_weather_manager) and \
			_weather_manager.weather_effect_applied.is_connected(_on_weather_effect_applied):
		_weather_manager.weather_effect_applied.disconnect(_on_weather_effect_applied)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	_map_controller = state.map_controller
	_task_manager = state.task_manager
	_loot_manager = state.loot_manager
	_command_context = state.command_context
	_router = state.command_router
	_calculate_initial_max_willpower() 

func _calculate_initial_max_willpower() -> void:
	if _unit_manager == null:
		_initial_max_willpower = {"player": 0, "enemy": 0, "neutral": 0}
		return

	_initial_max_willpower = {
		GameConstants.Faction.PLAYER: _unit_manager.get_fleet_willpower(GameConstants.Faction.PLAYER),
		GameConstants.Faction.ENEMY: _unit_manager.get_fleet_willpower(GameConstants.Faction.ENEMY),
		GameConstants.Faction.NEUTRAL: _unit_manager.get_fleet_willpower(GameConstants.Faction.NEUTRAL)
	}


func set_turn_controller(controller: TurnController) -> void:
	_turn_controller = controller

func set_command_context(command_context: GameCommandContext) -> void:
	_command_context = command_context

func set_router(router: InputCommandRouter) -> void:
	_router = router

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func execute_turn(ai_unit: Unit) -> bool:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		return false

	if not GameConstants.SILENT_LOGS:
		GameLogger.debug(GameLogger.Category.AI, "AIController: execute_turn for ", ai_unit.unit_name)
	var context := _build_context()
	var actions := _gather_actions(ai_unit, context)

	if actions.is_empty():
		return false

	actions.sort_custom(func(a: AIAction, b: AIAction) -> bool: return a.score > b.score)
	var best: AIAction = actions[0]

	return await _execute_action(ai_unit, best, context)

# ---------------------------------------------------------------------------
# Private — context & evaluator construction
# ---------------------------------------------------------------------------

func _build_context() -> AIContext:
	var ctx := AIContext.new()
	ctx.unit_manager = _unit_manager
	ctx.task_manager = _task_manager
	ctx.loot_manager = _loot_manager
	ctx.command_context = _command_context
	ctx.router = _router
	ctx.terrain_map = _map_controller.get_terrain_map() if _map_controller else null
	return ctx


# ---------------------------------------------------------------------------
# Private — action gathering
# ---------------------------------------------------------------------------

func _gather_actions(unit: Unit, context: AIContext) -> Array[AIAction]:
	var all_actions: Array[AIAction] = []

	for evaluator in _evaluators:
		var found := evaluator.evaluate(unit, context)
		all_actions.append_array(found)

	if _current_ai_modifier != 0.0:
		for action in all_actions:
			action.score += _current_ai_modifier * 10.0

	return all_actions

# ---------------------------------------------------------------------------
# Private — action execution
# ---------------------------------------------------------------------------

func _execute_action(unit: Unit, action: AIAction, context: AIContext) -> bool:
	var performed := false

	# Step 1: movement (if the action includes a path)
	if not action.path.is_empty() and context.terrain_map:
		performed = await _execute_movement(unit, action.path, context.terrain_map) or performed
		if not is_instance_valid(unit):
			return performed
		if performed:
			_promote_move_action(unit, action, context)

	# Step 2: interaction
	if unit.res.has_action_available():
		performed = _execute_interaction(unit, action, context) or performed

	return performed

func _execute_movement(unit: Unit, path: Array[Vector2i], terrain_map) -> bool:
	if path.is_empty():
		return false

	var budget: int = unit.movement.get_remaining_movement_points()
	var reachable_path = _truncate_path_to_reachable(unit, path, terrain_map, budget)
	if reachable_path.is_empty():
		return false

	var target: Vector2i = reachable_path.back()
	if target == unit.get_grid_location():
		return false

	if _command_context == null or _command_context.move_controller == null:
		if is_instance_valid(unit):
			await unit.movement.move_along_path(reachable_path)
		return true

	var payload := {
		GameConstants.Payload.UNIT_INDEX: _unit_manager.get_unit_index(unit),
		GameConstants.Payload.TARGET_COORD: target
	}
	var result := _router.execute(GameConstants.Commands.CommandID.MOVE_TO_COORD, payload)
	if result == null or result.is_failure():
		if _command_context.move_controller.has_method("cancel_move"):
			_command_context.move_controller.cancel_move()
		return false

	if is_inside_tree(): await get_tree().process_frame

	if _command_context.move_controller.has_method("confirm_move"):
		var safety := 0
		while unit.movement.has_tentative_move() and safety < 10:
			_command_context.move_controller.confirm_move()
			if is_inside_tree(): await get_tree().process_frame
			safety += 1

	return true

func _truncate_path_to_reachable(unit: Unit, path: Array[Vector2i], terrain_map, budget: int) -> Array[Vector2i]:
	if path.is_empty(): return []

	var pass_blockers = unit.movement.get_pass_through_blockers(unit.get_unit_manager())
	var stop_blockers = unit.movement.get_stop_blockers(unit.get_unit_manager())

	var reachable: Dictionary = unit.movement.compute_movement_range(unit.get_grid_location(), terrain_map, budget, pass_blockers)

	for i in range(path.size() - 1, -1, -1):
		var coord = path[i]
		if reachable.has(coord) and not stop_blockers.has(coord):
			return path.slice(0, i + 1)

	return []

func _execute_interaction(_unit: Unit, action: AIAction, _context: AIContext) -> bool:
	if action.command_id == GameConstants.Commands.CommandID.NONE:
		return false

	if _router == null:
		return false

	var result: CommandResult = _router.execute(action.command_id, action.command_payload)
	if result.is_failure():
		GameLogger.debug(GameLogger.Category.AI, "AIController: command failed — ", result.get_description())
		return false
	return true

# ---------------------------------------------------------------------------
# Private — post-move action promotion
# ---------------------------------------------------------------------------

func _promote_move_action(unit: Unit, action: AIAction, _context: AIContext) -> void:
	if not is_instance_valid(unit):
		return
	# Payloads are already pre-built by evaluators.
	# We just update the type for logging/UI purposes if the unit reached position.
	match action.type:
		GameConstants.ActionType.MOVE_TO_FIGHT:
			if is_instance_valid(action.target_object):
				action.type = GameConstants.ActionType.FIGHT

		GameConstants.ActionType.MOVE_TO_EXPLORE:
			action.type = GameConstants.ActionType.EXPLORE

		GameConstants.ActionType.MOVE_TO_VISIT:
			action.type = GameConstants.ActionType.VISIT

		GameConstants.ActionType.MOVE_TO_GATHER:
			action.type = GameConstants.ActionType.GATHER

		GameConstants.ActionType.MOVE_TO_TRAPPED:
			action.type = GameConstants.ActionType.TRAPPED

		GameConstants.ActionType.MOVE_TO_CONVINCE:
			action.type = GameConstants.ActionType.CONVINCE

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_weather_effect_applied(weather_attribute: WeatherAttribute) -> void:
	_current_ai_modifier = weather_attribute.ai_modifier
