class_name TaskEvaluator
extends AIActionEvaluator

const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

## Finds explore/visit and move-to-task actions for the given unit.
## Priority:
##   - Unit already at a workable task location → ACTION_EXPLORE (opposed) or ACTION_VISIT (unopposed)
##   - Reachable, unoccupied task coord         → ACTION_MOVE_TO_TASK (closer = better)
##   - Fallback                                 → nearest task coord regardless of threats


func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if context.task_manager == null or context.terrain_map == null:
		return []

	var profile = unit.get_combat_profile()
	var score_task_action = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_TASK if profile else GameConstants.AI.SCORE_TASK_BASE
	var score_move_to_task = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_MOVE_TO_TASK if profile else GameConstants.AI.SCORE_MOVE_TO_TASK

	var actions: Array[AIAction] = []
	var start_pos := unit.get_grid_location()

	# Can we work right now?
	if unit.res.has_action_available():
		var immediate_tasks = _TaskDiscovery.get_immediate_tasks(unit, start_pos, context.task_manager)
		for task in immediate_tasks:
			var is_opposed = _is_opposed_task(task)
			var action_type := GameConstants.AI.ACTION_EXPLORE if is_opposed else GameConstants.AI.ACTION_VISIT
			var weight = GameConstants.AI.WEIGHT_OPPOSED if is_opposed else GameConstants.AI.WEIGHT_UNOPPOSED
			actions.append(AIAction.new(action_type, task, [], score_task_action * weight))

	# Find tasks to move toward
	var active_tasks = _TaskDiscovery.get_active_tasks(context.task_manager, unit.faction)
	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
	for task in active_tasks:
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord):
			continue
		if context.unit_manager.is_occupied(task_coord):
			continue
		var path = unit.movement.get_path_to_coord(task_coord, context.terrain_map)
		if not path.is_empty():
			var is_threatened := threatened_hexes.has(task_coord)
			var score: float = score_move_to_task - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)
			actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_TASK, task_coord, path, score))

	# Fallback: try any task regardless of occupancy / threats
	if actions.is_empty():
		var fallback := _fallback_task_action(unit, context)
		if fallback:
			actions.append(fallback)

	return actions

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

func _fallback_task_action(unit: Unit, context: AIContext) -> AIAction:
	var active_objective = context.task_manager.get_active_objective()
	if not active_objective or not active_objective.current_stage:
		return null
	var best_path: Array = []
	var best_score := INF
	var best_coord := GameConstants.INVALID_COORD
	var faction_tasks = _TaskDiscovery.get_active_tasks(context.task_manager, unit.faction)
	for task in faction_tasks:
		if task == null or task.status != Task.Status.ACTIVE:
			continue
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord):
			continue
		var path = unit.movement.get_path_to_coord(task_coord, context.terrain_map)
		if not path.is_empty() and (best_path.is_empty() or path.size() < best_score):
			best_path = path
			best_score = path.size()
			best_coord = task_coord
	if best_path.is_empty():
		return null
	return AIAction.new(GameConstants.AI.ACTION_MOVE_TO_TASK, best_coord, best_path, 0.0)
