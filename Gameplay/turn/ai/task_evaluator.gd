class_name TaskEvaluator
extends AIActionEvaluator

const ExploreCommand = preload("res://Gameplay/commands/explore_command.gd")
const VisitCommand = preload("res://Gameplay/commands/visit_command.gd")

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var score_task_base: float = float(profile.get_weight(&"task")) * GameConstants.AI.MULTIPLIER_TASK if profile else GameConstants.AI.SCORE_TASK_BASE
	var score_move_to_task: float = score_task_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var start_pos: Vector2i = unit.get_grid_location()
	var unit_index := context.unit_manager.get_unit_index(unit)

	# 1. Check for tasks at or adjacent to current position
	var task_manager: TaskManager = context.task_manager
	var immediate_tasks: Array[Task] = TargetDiscoveryService.get_immediate_tasks(unit, start_pos, task_manager)

	for task: Task in immediate_tasks:
		var score: float = score_task_base
		var is_opposed := _is_opposed_task(task)
		if is_opposed:
			score *= GameConstants.AI.WEIGHT_OPPOSED
		else:
			score *= GameConstants.AI.WEIGHT_UNOPPOSED

		var action := AIAction.new(GameConstants.ActionType.EXPLORE if is_opposed else GameConstants.ActionType.VISIT, score)
		if is_opposed:
			action.command_id = GameConstants.Commands.CommandID.EXPLORE
			action.command_payload = ExploreCommand.create_payload(unit_index, String(task.id))
		else:
			action.command_id = GameConstants.Commands.CommandID.VISIT
			action.command_payload = VisitCommand.create_payload(unit_index, String(task.id))
		action.target_object = task
		actions.append(action)

	# 2. Check for tasks reachable by moving
	if actions.is_empty():
		_add_move_to_task_actions(unit, context, score_move_to_task, actions, unit_index)

	# 3. Fallback: move toward any active task even if not reachable this turn
	if actions.is_empty():
		var fallback: AIAction = _fallback_task_action(unit, context, unit_index)
		if fallback:
			actions.append(fallback)

	return actions

func _add_move_to_task_actions(unit: Unit, context: AIContext, base_score: float, actions: Array[AIAction], unit_index: int) -> void:
	var discovery_results: Dictionary = _discover_nearby(unit, context, [TargetDiscoveryService.TASK])
	var active_tasks: Array[Task] = []
	if discovery_results.has(TargetDiscoveryService.TASK):
		active_tasks.assign(discovery_results[TargetDiscoveryService.TASK])

	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)

	for task: Task in active_tasks:
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord) or context.unit_manager.is_occupied(task_coord):
			continue

		var path: Array[Vector2i] = unit.movement.get_path_to_coord(task_coord, context.terrain_map, unit.get_grid_location(), 50)
		if not path.is_empty():
			var end_pos: Vector2i = path.back()
			var is_threatened: bool = threatened_hexes.has(end_pos)
			var score: float = base_score - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)

			var is_opposed := _is_opposed_task(task)
			var action := AIAction.new(GameConstants.ActionType.MOVE_TO_TASK, score)
			if is_opposed:
				action.command_id = GameConstants.Commands.CommandID.EXPLORE
				action.command_payload = ExploreCommand.create_payload(unit_index, String(task.id))
			else:
				action.command_id = GameConstants.Commands.CommandID.VISIT
				action.command_payload = VisitCommand.create_payload(unit_index, String(task.id))
			action.target_object = task
			action.path = path
			action.move_cost = path.size()
			actions.append(action)


# -- helpers -------------------------------------------------------------------

func _is_opposed_task(task: Task) -> bool:
	if task and task.is_opposed:
		return true
	return task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT

func _is_invalid_coord(coord: Vector2i) -> bool:
	return coord == GameConstants.INVALID_COORD

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	if unit.movement:
		return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}

func _fallback_task_action(unit: Unit, context: AIContext, unit_index: int) -> AIAction:
	var discovery_results := _discover_nearby(unit, context, [TargetDiscoveryService.TASK])
	var faction_tasks: Array[Task] = discovery_results.get(TargetDiscoveryService.TASK, [])

	var best_path: Array[Vector2i] = []
	var best_score := -INF
	var best_task: Task = null

	for task: Task in faction_tasks:
		var path: Array[Vector2i] = unit.movement.get_path_to_near(task.target_coord, context.terrain_map, context.unit_manager)
		if not path.is_empty():
			var score := -float(path.size())
			if score > best_score:
				best_score = score
				best_path = path
				best_task = task

	if best_task:
		var is_opposed := _is_opposed_task(best_task)
		var action := AIAction.new(GameConstants.ActionType.MOVE_TO_TASK, GameConstants.AI.SCORE_TASK_BASE * GameConstants.AI.RATIO_FALLBACK_ACTION)
		if is_opposed:
			action.command_id = GameConstants.Commands.CommandID.EXPLORE
			action.command_payload = ExploreCommand.create_payload(unit_index, String(best_task.id))
		else:
			action.command_id = GameConstants.Commands.CommandID.VISIT
			action.command_payload = VisitCommand.create_payload(unit_index, String(best_task.id))
		action.target_object = best_task
		action.path = best_path
		action.move_cost = best_path.size()
		return action

	return null
