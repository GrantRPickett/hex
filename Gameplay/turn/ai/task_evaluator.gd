class_name TaskEvaluator
extends AIActionEvaluator

## Finds work-on-task and move-to-task actions for the given unit.
## Priority:
##   - Unit already at a workable task location → ACTION_WORK_ON_TASK
##   - Reachable, unoccupied task coord         → ACTION_MOVE_TO_TASK (closer = better)
##   - Fallback                                 → nearest task coord regardless of threats

const ACTION_WORK_ON_TASK := &"work_on_task"
const ACTION_MOVE_TO_TASK := &"move_to_task"

const SCORE_WORK_ON_TASK := 80.0
const SCORE_MOVE_TO_TASK := 20.0
const THREAT_PENALTY := 5.0

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if context.task_manager == null or context.terrain_map == null:
		return []

	var profile = unit.get_combat_profile()
	var score_work_on_task = float(profile.get_weight(&"objective")) * 16.0 if profile else SCORE_WORK_ON_TASK
	var score_move_to_task = float(profile.get_weight(&"objective")) * 4.0 if profile else SCORE_MOVE_TO_TASK

	var actions: Array[AIAction] = []
	var start_pos := unit.get_grid_location()

	# Can we work right now?
	if unit.res.has_action_available():
		var location = context.task_manager.get_location_at(start_pos)
		if location:
			var task = context.task_manager.get_task_for_target(location)
			if task and task.can_be_worked_on_by(unit):
				actions.append(AIAction.new(ACTION_WORK_ON_TASK, task, [], score_work_on_task))

	# Find tasks to move toward
	var active_objective = context.task_manager.get_active_objective()
	if active_objective and active_objective.current_stage:
		var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
		for task in active_objective.current_stage.active_tasks:
			if task == null or task.status != Task.Status.ACTIVE:
				continue
			var task_coord: Vector2i = task.target_coord
			if _is_invalid_coord(task_coord):
				continue
			if context.unit_manager.is_occupied(task_coord):
				continue
			var path = unit.movement.get_path_to_coord(task_coord, context.terrain_map)
			if not path.is_empty():
				var is_threatened := threatened_hexes.has(task_coord)
				var score: float = score_move_to_task - path.size() - (THREAT_PENALTY if is_threatened else 0.0)
				actions.append(AIAction.new(ACTION_MOVE_TO_TASK, task_coord, path, score))

	# Fallback: try any task regardless of occupancy / threats
	if actions.is_empty():
		var fallback := _fallback_task_action(unit, context)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_invalid_coord(coord: Vector2i) -> bool:
	return coord == Vector2i(-1, -1) or coord == Vector2i(-999, -999)

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
	var best_coord := Vector2i(-1, -1)
	for task in active_objective.current_stage.active_tasks:
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
	return AIAction.new(ACTION_MOVE_TO_TASK, best_coord, best_path, 0.0)
