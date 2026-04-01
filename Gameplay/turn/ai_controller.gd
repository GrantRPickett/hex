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
var _location_service: LocationService
var _turn_controller: TurnController
var _command_context: GameCommandContext
var _router: InputCommandRouter

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
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
	_location_service = state.location_service
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

func set_location_service(service: LocationService) -> void:
	_location_service = service

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func execute_turn(ai_unit: Unit) -> bool:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		return false

	# Debug overrides for movement/AI processing
	if ai_unit.faction == GameConstants.Faction.ENEMY and not GameConstants.debug_enemy_movement_enabled:
		return false
	if ai_unit.faction == GameConstants.Faction.NEUTRAL and not GameConstants.debug_neutral_movement_enabled:
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
	ctx.location_service = _location_service
	ctx.command_context = _command_context
	ctx.router = _router
	ctx.terrain_map = _map_controller.get_terrain_map() if _map_controller else null
	return ctx


# ---------------------------------------------------------------------------
# Private — action gathering
# ---------------------------------------------------------------------------

func _gather_actions(unit: Unit, context: AIContext) -> Array[AIAction]:
	var all_actions: Array[AIAction] = []
	var player_actions := PlayerActionManager.get_available_actions_with_weather(unit, context.terrain_map, context.unit_manager, _weather_manager)

	for pa in player_actions:
		_process_player_action(unit, pa, context, all_actions)

	# 2. Add Center Fallback if we have movement available
	if unit.res.has_move_available():
		_append_center_fallback_action(unit, context, all_actions)

	if _current_ai_modifier != 0.0:
		for action in all_actions:
			action.score += _current_ai_modifier * 10.0

	return all_actions

func _append_center_fallback_action(unit: Unit, context: AIContext, out_actions: Array[AIAction]) -> void:
	if context.terrain_map == null:
		return

	var width: int = context.terrain_map.grid_width
	var height: int = context.terrain_map.grid_height
	if width <= 0 or height <= 0:
		return

	var center := Vector2i(max(1, int(round(width * 0.5))), max(1, int(round(height * 0.5)))) # Simplified fallback center
	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	if context.terrain_map.has_method("get_offset_axis"):
		axis = context.terrain_map.get_offset_axis() as TileSet.TileOffsetAxis

	var threatened_hexes := unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map) if unit.movement else {}

	# Sort a sampling of tiles by distance to center
	var candidates: Array[Vector2i] = []
	var step := 2 # Sample every other tile for performance
	for x in range(0, width, step):
		for y in range(0, height, step):
			candidates.append(Vector2i(x, y))

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return HexLib.get_distance(center, a, axis) < HexLib.get_distance(center, b, axis)
	)

	var unit_index := context.unit_manager.get_unit_index(unit)
	for coord in candidates:
		if context.unit_manager.is_occupied(coord): continue
		var path := unit.movement.get_path_to_coord(coord, context.terrain_map)
		if path.is_empty(): continue

		var is_threatened := threatened_hexes.has(coord)
		var score: float = float(GameConstants.AI.SCORE_MOVE_TO_CENTER) - path.size() - (float(GameConstants.AI.THREAT_PENALTY) if is_threatened else 0.0)

		var action := AIAction.new(GameConstants.ActionType.MOVE_TO_CENTER, score)
		action.command_id = GameConstants.ActionType.MOVE_TO_COORD
		action.command_payload = {
			GameConstants.Payload.UNIT_INDEX: unit_index,
			GameConstants.Payload.TARGET_COORD: coord
		}
		action.path = path
		action.move_cost = path.size()
		out_actions.append(action)
		break # Only need one best center candidate

func _process_player_action(unit: Unit, pa: PlayerAction, context: AIContext, out_actions: Array[AIAction]) -> void:
	if pa.targets.is_empty() and pa.reachable_targets.is_empty():
		# Self-targeted or global actions (WAIT, some SKILLS)
		var score = _calculate_score(unit, pa, null, context)
		out_actions.append(_convert_pa_to_ai(unit, pa, null, score, context))
		return

	# Near targets
	for target in pa.targets:
		var score = _calculate_score(unit, pa, target, context)
		out_actions.append(_convert_pa_to_ai(unit, pa, target, score, context))

	# Far targets
	for target in pa.reachable_targets:
		var score = _calculate_score(unit, pa, target, context)
		out_actions.append(_convert_pa_to_ai(unit, pa, target, score, context))

func _calculate_score(unit: Unit, pa: PlayerAction, target: Target, context: AIContext) -> float:
	var base_score := _get_base_score_for_type(pa.type, unit)
	var final_score := base_score

	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var weight_key := _get_weight_key_for_type(pa.type)
	if profile and not weight_key.is_empty():
		var weight = profile.get_weight(weight_key)
		if weight == 0: weight = 5 # Default fallback weight
		final_score = float(weight) * _get_multiplier_for_type(pa.type)

	# Opposed/Unopposed weighting
	var is_opposed := _is_action_opposed(pa)
	final_score *= GameConstants.AI.WEIGHT_OPPOSED if is_opposed else GameConstants.AI.WEIGHT_UNOPPOSED

	# Quality multiplier for combat/interactions
	if target and unit.get_combat_system():
		var interaction_type := _get_interaction_type_str(pa.type)
		var best_attr := unit.get_best_attribute_index()
		var quality := unit.get_combat_system().get_attack_quality(unit, target, best_attr, interaction_type)
		final_score *= _get_quality_multiplier_float(quality)

	# Distance and threat penalties
	if target:
		var move_data = pa.target_move_data.get(target)
		if move_data:
			var cost = move_data.get("cost", 0)
			final_score -= (cost * 2.0) # Heavier penalty for distance to favor immediate actions

			var dest_coord = move_data.get("coord", GameConstants.INVALID_COORD)
			var threatened_hexes = unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map) if unit.movement else {}
			if threatened_hexes.has(dest_coord):
				final_score -= GameConstants.AI.THREAT_PENALTY

	return final_score

func _get_interaction_type_str(type: GameConstants.ActionType) -> String:
	return GameConstants.get_interaction_from_type(type)

func _is_action_opposed(pa: PlayerAction) -> bool:
	match pa.type:
		GameConstants.ActionType.FIGHT, \
		GameConstants.ActionType.TRAPPED, \
		GameConstants.ActionType.EXPLORE:
			return true
	return false

func _get_base_score_for_type(type: GameConstants.ActionType, _unit: Unit) -> float:
	match type:
		GameConstants.ActionType.FIGHT: return float(GameConstants.AI.SCORE_FIGHT_BASE)
		GameConstants.ActionType.CONVINCE: return float(GameConstants.AI.SCORE_CONVINCE_BASE)
		GameConstants.ActionType.GATHER: return float(GameConstants.AI.SCORE_GATHER_BASE)
		GameConstants.ActionType.TRAPPED: return float(GameConstants.AI.SCORE_TRAPPED_BASE)
		GameConstants.ActionType.EXPLORE: return float(GameConstants.AI.SCORE_TASK_BASE)
		GameConstants.ActionType.VISIT: return float(GameConstants.AI.SCORE_TASK_BASE)
		GameConstants.ActionType.AID: return float(GameConstants.AI.SCORE_AID_ALLY_BASE)
		GameConstants.ActionType.MOVE_TO_CENTER: return float(GameConstants.AI.SCORE_MOVE_TO_CENTER)
		_: return 10.0

func _get_weight_key_for_type(type: GameConstants.ActionType) -> StringName:
	match type:
		GameConstants.ActionType.FIGHT: return &"attack"
		GameConstants.ActionType.CONVINCE, \
		GameConstants.ActionType.GATHER, \
		GameConstants.ActionType.TRAPPED, \
		GameConstants.ActionType.EXPLORE, \
		GameConstants.ActionType.VISIT:
			return &"objective"
		GameConstants.ActionType.AID: return &"protect_ally"
		_: return &""

func _get_multiplier_for_type(type: GameConstants.ActionType) -> float:
	match type:
		GameConstants.ActionType.FIGHT: return float(GameConstants.AI.MULTIPLIER_FIGHT)
		GameConstants.ActionType.CONVINCE: return float(GameConstants.AI.MULTIPLIER_CONVINCE)
		GameConstants.ActionType.GATHER: return float(GameConstants.AI.MULTIPLIER_GATHER)
		GameConstants.ActionType.TRAPPED: return float(GameConstants.AI.MULTIPLIER_TRAPPED)
		GameConstants.ActionType.EXPLORE: return float(GameConstants.AI.MULTIPLIER_EXPLORE)
		GameConstants.ActionType.VISIT: return float(GameConstants.AI.MULTIPLIER_VISIT)
		GameConstants.ActionType.AID: return float(GameConstants.AI.MULTIPLIER_AID_ALLY)
		_: return 1.0

func _get_quality_multiplier_float(quality: GameConstants.Combat.AttackQuality) -> float:
	match quality:
		GameConstants.Combat.AttackQuality.SUCCESS: return GameConstants.AI.QUALITY_MULTIPLIER_SUCCESS
		GameConstants.Combat.AttackQuality.PROGRESS: return GameConstants.AI.QUALITY_MULTIPLIER_PROGRESS
		GameConstants.Combat.AttackQuality.RISKY: return GameConstants.AI.QUALITY_MULTIPLIER_RISKY
		GameConstants.Combat.AttackQuality.IDLE: return GameConstants.AI.QUALITY_MULTIPLIER_IDLE
		_: return GameConstants.AI.QUALITY_MULTIPLIER_INEFFECTIVE

func _convert_pa_to_ai(unit: Unit, pa: PlayerAction, target: Target, score: float, context: AIContext) -> AIAction:
	var best_attr := unit.get_best_attribute_index()
	var final_pa := pa

	if target:
		final_pa = PlayerActionManager.create_move_and_interact_action(pa, target, pa.target_move_data, context.unit_manager, best_attr)

	var ai_action := AIAction.new(final_pa.type, score)
	ai_action.command_id = final_pa.command_id
	ai_action.command_payload = final_pa.command_payload
	ai_action.target_object = target

	# Path calculation if needed (from unit's current position)
	var move_data = pa.target_move_data.get(target) if target else null
	if move_data:
		var dest = move_data.get("coord", GameConstants.INVALID_COORD)
		if dest != GameConstants.INVALID_COORD and dest != unit.get_grid_location():
			ai_action.path = unit.movement.get_path_to_coord(dest, context.terrain_map, unit.get_grid_location())
			ai_action.move_cost = ai_action.path.size()

	return ai_action

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
	var result := _router.execute(GameConstants.ActionType.MOVE_TO_COORD, payload)
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
	if action.command_id == GameConstants.ActionType.NONE:
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
