class_name AIController
extends Node

## Orchestrates AI turn execution.
##
## Responsibilities (single, clear):
##   1. Build an AIContext from injected dependencies.
##   2. Run each registered AIActionEvaluator to gather candidate actions.
##   3. Apply external modifiers (e.g. weather) to the scores.
##   4. Select the highest-scoring action.
##   5. Execute movement (if the action includes a path).
##   6. Promote move-only actions to their interaction counterpart (if unit
##      landed on the target after moving).
##   7. Execute the interaction via AICommandBuilder.
##
## All per-action-type logic lives in the evaluator classes and AICommandBuilder.

# ---------------------------------------------------------------------------
# Dependencies (injected by GameSessionBuilder / setup())
# ---------------------------------------------------------------------------
var _unit_manager: UnitManager
var _map_controller: MapController
var _task_manager: TaskManager
var _loot_manager: LootManager
var _turn_controller: TurnController
var _command_context: GameCommandContext

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
var _evaluators: Array[AIActionEvaluator] = []
var _command_builder: AICommandBuilder = AICommandBuilder.new()
var _current_ai_modifier: float = 0.0

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
	_rebuild_evaluators(state)

func set_turn_controller(controller: TurnController) -> void:
	_turn_controller = controller

func set_command_context(command_context: GameCommandContext) -> void:
	_command_context = command_context
	# Re-create evaluators so they see the new context on next evaluate pass
	_rebuild_evaluators(null)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Execute one AI turn for [param ai_unit].
## Returns true if the unit performed any action.
func execute_turn(ai_unit: Unit) -> bool:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		print_debug("AIController: skipping invalid/exhausted unit")
		return false

	print_debug("AIController: execute_turn for ", ai_unit.unit_name)
	var context := _build_context()
	var actions := _gather_actions(ai_unit, context)

	if actions.is_empty():
		print_debug("AIController: no actions available for ", ai_unit.unit_name)
		return false

	actions.sort_custom(func(a: AIAction, b: AIAction) -> bool: return a.score > b.score)
	var best: AIAction = actions[0]
	print_debug("AIController: best action=%s score=%.1f for %s" % [best.type, best.score, ai_unit.unit_name])

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
	ctx.terrain_map = _map_controller.get_terrain_map() if _map_controller else null
	return ctx

func _rebuild_evaluators(_state) -> void:
	# Ordered by conceptual priority (higher-priority evaluators first ensures
	# that if two evaluators produce equal-scored actions the natural order is
	# already sensible — though final selection is by score anyway).
	_evaluators = [
		AidAllyEvaluator.new(),
		LootEvaluator.new(),
		TaskEvaluator.new(),
		AttackEvaluator.new(),
		TalkEvaluator.new(),
		CenterFallbackEvaluator.new(), # last resort
	]

# ---------------------------------------------------------------------------
# Private — action gathering
# ---------------------------------------------------------------------------

func _gather_actions(unit: Unit, context: AIContext) -> Array[AIAction]:
	var all_actions: Array[AIAction] = []

	for evaluator in _evaluators:
		var found := evaluator.evaluate(unit, context)
		all_actions.append_array(found)

	# Apply global weather modifier to every candidate
	if _current_ai_modifier != 0.0:
		for action in all_actions:
			action.score += _current_ai_modifier * 10.0

	print_debug("AIController: gathered %d candidate actions for %s" % [all_actions.size(), unit.unit_name])
	return all_actions

# ---------------------------------------------------------------------------
# Private — action execution
# ---------------------------------------------------------------------------

func _execute_action(unit: Unit, action: AIAction, context: AIContext) -> bool:
	var performed := false

	# Step 1: movement (if the action includes a path)
	if not action.path.is_empty() and context.terrain_map:
		performed = await _execute_movement(unit, action.path, context.terrain_map) or performed
		if performed:
			_promote_move_action(unit, action, context)

	# Step 2: interaction
	if unit.res.has_action_available():
		performed = _execute_interaction(unit, action, context) or performed

	return performed

func _execute_movement(unit: Unit, path: Array, _terrain_map) -> bool:
	if path.is_empty():
		return false
	var target: Vector2i = path.back() if path.back() is Vector2i else path[-1]
	if target == unit.get_grid_location():
		return false

	if _command_context == null or _command_context.move_controller == null:
		await unit.movement.move_along_path(path)
		return true

	var result := MoveToCoordCommand.new().execute(_command_context, {"coord": target})
	if result == null or result.is_failure():
		if _command_context.move_controller.has_method("cancel_move"):
			_command_context.move_controller.cancel_move()
		return false

	await get_tree().process_frame
	if _command_context.move_controller.has_method("confirm_move"):
		_command_context.move_controller.confirm_move()
	await get_tree().process_frame
	return true

func _execute_interaction(unit: Unit, action: AIAction, context: AIContext) -> bool:
	var cmd_data: Dictionary = _command_builder.build(action, unit, context)
	if cmd_data.is_empty():
		return false
	return _execute_command(cmd_data["cmd"], cmd_data["payload"])

func _execute_command(cmd: GameCommand, payload: Dictionary) -> bool:
	if cmd == null or _command_context == null:
		return false
	var result = cmd.execute(_command_context, payload)
	if result.is_failure():
		print_debug("AIController: command failed — ", result.get_description())
		return false
	return true

# ---------------------------------------------------------------------------
# Private — post-move action promotion
# ---------------------------------------------------------------------------
## After moving, convert a "move-to-X" action type to its executable "do-X"
## counterpart if the unit is now in position to act.

func _promote_move_action(unit: Unit, action: AIAction, context: AIContext) -> void:
	match action.type:
		&"move_to_enemy":
			if is_instance_valid(action.target):
				action.type = &"attack"

		&"move_to_task":
			if context.task_manager == null:
				return
			var location = context.task_manager.get_location_at(unit.get_grid_location())
			if location:
				var task = context.task_manager.get_task_for_target(location)
				if task and task.can_be_worked_on_by(unit):
					action.type = &"work_on_task"
					action.target = task

		&"move_to_loot":
			if context.loot_manager == null:
				return
			var coord := unit.get_grid_location()
			if context.loot_manager.has_loot_at(coord):
				action.type = &"loot"
				action.target = coord

		&"move_to_talk":
			var target_unit := action.target as Unit
			if not is_instance_valid(target_unit):
				return
			var dialogue_service = context.command_context.dialogue_action_service \
					if context.command_context else null
			if dialogue_service == null:
				dialogue_service = UnitActionManager.get_dialogue_service()
			if dialogue_service == null:
				return
			var dialogue_actions: Array[Dictionary] = []
			dialogue_service.append_dialogue_actions(dialogue_actions, unit, context.unit_manager)
			var target_index := context.unit_manager.get_unit_index(target_unit)
			for d_action in dialogue_actions:
				if int(d_action.get("target_index", -1)) == target_index:
					action.type = &"talk"
					action.target = {
						"dialogue_id": d_action.get("dialogue_id"),
						"initiator_index": d_action.get("initiator_index"),
						"target_index": target_index
					}
					break

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_weather_effect_applied(weather_attribute: WeatherAttribute) -> void:
	_current_ai_modifier = weather_attribute.ai_modifier
	print_debug("AIController: weather modifier updated to ", _current_ai_modifier)
