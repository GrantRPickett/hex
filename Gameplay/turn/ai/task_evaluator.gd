class_name TaskEvaluator
extends AIActionEvaluator

## Finds explore/visit and move-to-task actions for the given unit.
## Priority:
##   - Unit already at a workable task location → ACTION_EXPLORE (opposed) or ACTION_VISIT (unopposed)
##   - Reachable, unoccupied task coord		 → ACTION_MOVE_TO_TASK (closer = better)
##   - Fallback								 → nearest task coord regardless of threats


func evaluate(unit: _Unit, context: _AIContext) -> Array[_AIAction]:
	if context.task_manager == null or context.terrain_map == null:
		return []

	var scores = _calculate_scores(unit, context)
	var actions: Array[_AIAction] = []
	
	_add_immediate_task_actions(unit, context, scores.task, actions)
	_add_move_to_task_actions(unit, context, scores.move, actions)

	if actions.is_empty():
		var fallback := _fallback_task_action(unit, context)
		if fallback:
			actions.append(fallback)

	return actions

func _calculate_scores(unit: _Unit, context: _AIContext) -> Dictionary:
	var profile = unit.get_combat_profile()
	var base_score_task = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_TASK if profile else GameConstants.AI.SCORE_TASK_BASE
	var base_score_move = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_MOVE_TO_TASK if profile else GameConstants.AI.SCORE_MOVE_TO_TASK

	var morale_factor = _calculate_morale_factor(unit, context)
	var adjustment = (morale_factor - 1.0) * GameConstants.AI.SCORE_MORALE_ADJUSTMENT_MAX * DifficultyService.get_ai_scaling_factor()

	return {
		"task": base_score_task + adjustment,
		"move": base_score_move + adjustment
	}

func _calculate_morale_factor(unit: _Unit, context: _AIContext) -> float:
	var personal_ratio = _get_personal_willpower_ratio(unit)
	var group_ratio = _get_group_morale_ratio(unit, context)
	var weight = DifficultyService.get_ai_morale_weight()
	return lerp(personal_ratio, group_ratio, weight)

func _add_immediate_task_actions(unit: _Unit, context: _AIContext, base_score: float, actions: Array[_AIAction]) -> void:
	if not unit.res.has_action_available():
		return
		
	var start_pos := unit.get_grid_location()
	var immediate_tasks = TaskDiscovery.get_immediate_tasks(unit, start_pos, context.task_manager)
	
	for task in immediate_tasks:
		var action_type : StringName
		var weight_val := GameConstants.AI.WEIGHT_UNOPPOSED
		
		if task.event_type == GameConstants.TaskEvents.LOOT:
			action_type = GameConstants.AI.ACTION_LOOT
		elif _is_opposed_task(task):
			action_type = GameConstants.AI.ACTION_EXPLORE
			weight_val = GameConstants.AI.WEIGHT_OPPOSED
		else:
			action_type = GameConstants.AI.ACTION_VISIT
		
		var target = task if action_type != GameConstants.AI.ACTION_LOOT else task.target_coord
		actions.append(_AIAction.new(action_type, target, [], base_score * weight_val))

func _add_move_to_task_actions(unit: _Unit, context: _AIContext, base_score: float, actions: Array[_AIAction]) -> void:
	var active_tasks = TaskDiscovery.get_active_tasks(context.task_manager, unit.faction)
	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
	
	for task in active_tasks:
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord) or context.unit_manager.is_occupied(task_coord):
			continue
		
		var path = unit.movement.get_path_to_coord(task_coord, context.terrain_map, Vector2i.MAX, 50)
		if not path.is_empty():
			var is_threatened := threatened_hexes.has(task_coord)
			var score: float = base_score - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)
			actions.append(_AIAction.new(GameConstants.AI.ACTION_MOVE_TO_TASK, task_coord, path, score))


# -- helpers -------------------------------------------------------------------

func _is_opposed_task(task: Task) -> bool:
	if task and task.is_opposed:
		return true
	return task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT

func _is_invalid_coord(coord: Vector2i) -> bool:
	return coord == GameConstants.INVALID_COORD

func _get_threatened_hexes(unit: _Unit, context: _AIContext) -> Dictionary:
	if unit.movement:
		return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}

func _fallback_task_action(unit: _Unit, context: _AIContext) -> _AIAction:
	var active_objective = context.task_manager.get_active_objective()
	if not active_objective or not active_objective.current_stage:
		return null
	var best_path: Array = []
	var best_score := INF
	var best_coord := GameConstants.INVALID_COORD
	var faction_tasks = TaskDiscovery.get_active_tasks(context.task_manager, unit.faction)
	for task in faction_tasks:
		if task == null or task.status != Task.Status.ACTIVE:
			continue
		var task_coord: Vector2i = task.target_coord
		if _is_invalid_coord(task_coord):
			continue
		var path = unit.movement.get_path_to_coord(task_coord, context.terrain_map, Vector2i.MAX, 50)
		if not path.is_empty() and (best_path.is_empty() or path.size() < best_score):
			best_path = path
			best_score = path.size()
			best_coord = task_coord
	if best_path.is_empty():
		return null
	return _AIAction.new(GameConstants.AI.ACTION_MOVE_TO_TASK, best_coord, best_path, 0.0)


func _get_personal_willpower_ratio(unit: _Unit) -> float:
	if unit.max_willpower <= 0:
		return 1.0
	return float(unit.willpower) / unit.max_willpower


func _get_group_morale_ratio(unit: _Unit, context: _AIContext) -> float:
	if context.unit_manager == null:
		return 1.0

	var faction_units: Array[Unit] = []
	var initial_max := 0

	match unit.faction:
		_Unit.Faction.PLAYER:
			faction_units = context.unit_manager.get_player_units()
			initial_max = context.initial_max_willpower.get("player", 0)
		_Unit.Faction.ENEMY:
			faction_units = context.unit_manager.get_enemy_units()
			initial_max = context.initial_max_willpower.get("enemy", 0)
		_Unit.Faction.NEUTRAL:
			faction_units = context.unit_manager.get_neutral_units()
			initial_max = context.initial_max_willpower.get("neutral", 0)

	if initial_max <= 0:
		return 1.0

	var current_total := 0
	for u in faction_units:
		if is_instance_valid(u):
			current_total += u.willpower

	return float(current_total) / initial_max
