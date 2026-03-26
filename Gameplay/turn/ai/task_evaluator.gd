class_name TaskEvaluator
extends AIActionEvaluator

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var score_task_base: float = float(profile.get_weight(&"task")) * GameConstants.AI.MULTIPLIER_TASK if profile else GameConstants.AI.SCORE_TASK_BASE
	var actions: Array[AIAction] = []
	var start_pos: Vector2i = unit.get_grid_location()

	# 1. Immediate tasks (at or adjacent)
	for task in TargetDiscoveryService.get_immediate_tasks(unit, start_pos, context.task_manager):
		var score := _get_task_score(unit, context, task, score_task_base)
		actions.append(_create_task_action(unit, context, task, score))

	# 2. Reachable tasks
	if actions.is_empty():
		_add_move_to_task_actions(unit, context, score_task_base, actions)

	# 3. Fallback: distant tasks
	if actions.is_empty():
		var fallback := _fallback_task_action(unit, context)
		if fallback:
			actions.append(fallback)

	return actions

func _add_move_to_task_actions(unit: Unit, context: AIContext, base_score: float, actions: Array[AIAction]) -> void:
	var discovery_results: Dictionary = _discover_nearby(unit, context, [TargetDiscoveryService.TASK])
	var active_tasks: Array[Task] = []
	if discovery_results.has(TargetDiscoveryService.TASK):
		active_tasks.assign(discovery_results[TargetDiscoveryService.TASK])

	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
	var score_move_to_task := base_score * GameConstants.AI.RATIO_MOVE_TO_TARGET

	for task: Task in active_tasks:
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord) or context.unit_manager.is_occupied(task_coord):
			continue

		var path: Array[Vector2i] = unit.movement.get_path_to_coord(task_coord, context.terrain_map, unit.get_grid_location(), 50)
		if not path.is_empty():
			var end_pos: Vector2i = path.back()
			var score := _get_task_score(unit, context, task, score_move_to_task)
			score -= path.size() + (GameConstants.AI.THREAT_PENALTY if threatened_hexes.has(end_pos) else 0.0)

			actions.append(_create_task_action(unit, context, task, score, path))

func _get_task_score(unit: Unit, context: AIContext, task: Task, base_score: float) -> float:
	var score := base_score
	var is_opposed := _is_opposed_task(task)
	if is_opposed:
		score *= GameConstants.AI.WEIGHT_OPPOSED
		var combat_system := unit.get_combat_system()
		if combat_system:
			var target = context.task_manager.get_target_by_id(task.target_id)
			if not target:
				target = context.task_manager.get_target_at(task.target_coord)
			var quality = combat_system.get_task_quality(unit, target, task)
			score *= _get_quality_multiplier(quality)
	else:
		score *= GameConstants.AI.WEIGHT_UNOPPOSED
		score *= GameConstants.AI.QUALITY_MULTIPLIER_SUCCESS
	return score

func _create_task_action(unit: Unit, context: AIContext, task: Task, score: float, path: Array[Vector2i] = []) -> AIAction:
	var unit_index := context.unit_manager.get_unit_index(unit)
	var is_opposed := _is_opposed_task(task)
	var is_moving := not path.is_empty()

	var type: GameConstants.ActionType
	var interaction: String

	if is_moving:
		type = GameConstants.ActionType.MOVE_TO_EXPLORE if is_opposed else GameConstants.ActionType.MOVE_TO_VISIT
	else:
		type = GameConstants.ActionType.EXPLORE if is_opposed else GameConstants.ActionType.VISIT

	interaction = GameConstants.Interactions.EXPLORE if is_opposed else GameConstants.Interactions.VISIT

	var action := AIAction.new(type, score)
	action.command_id = GameConstants.Commands.CommandID.INTERACT
	action.command_payload = PerformInteractionCommand.create_payload(unit_index, task.target_coord, interaction, {GameConstants.Payload.TASK_ID: String(task.id)})
	action.target_object = task
	if is_moving:
		action.path = path
		action.move_cost = path.size()
	return action

func _fallback_task_action(unit: Unit, context: AIContext) -> AIAction:
	var discovery_results := _discover_nearby(unit, context, [TargetDiscoveryService.TASK])
	var faction_tasks: Array[Task] = discovery_results.get(TargetDiscoveryService.TASK, [])
	var best_path: Array[Vector2i] = []
	var best_score := -INF
	var best_task: Task = null

	for task in faction_tasks:
		var path: Array[Vector2i] = unit.movement.get_path_to_near(task.target_coord, context.terrain_map, context.unit_manager)
		if not path.is_empty():
			var score := -float(path.size())
			if score > best_score:
				best_score = score
				best_path = path
				best_task = task

	if best_task:
		var score := GameConstants.AI.SCORE_TASK_BASE * GameConstants.AI.RATIO_FALLBACK_ACTION
		return _create_task_action(unit, context, best_task, score, best_path)
	return null

# -- static utilities ---------------------------------------------------------

func _is_opposed_task(task: Task) -> bool:
	if task and task.is_opposed: return true
	return task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT

func _is_invalid_coord(coord: Vector2i) -> bool:
	return coord == GameConstants.INVALID_COORD

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map) if unit.movement else {}
