class_name TaskResolutionService
extends RefCounted

## Result object for Task and Target resolution.
class TaskResolutionResult:
	var task: Task
	var target: Target
	var unit: Unit
	var location: Location
	var loot: Loot
	var is_narrative: bool
	var resolution_mode: String

## Resolves a Task and Target from a variety of payload types.
## Returns a TaskResolutionResult with typed fields.
static func resolve_task_and_target(
	context: GameCommandContext,
	payload: Variant,
	required_event: String,
	faction: int = GameConstants.INVALID_INDEX
) -> TaskResolutionResult:
	var task: Task = null
	var target: Target = null
	var manager: TaskManager = context.task_manager if context else null

	if payload is Task:
		task = payload
	elif payload is Target:
		target = payload
	elif payload is Dictionary:
		# 1. Direct Target Node
		var raw_target = payload.get(GameConstants.Payload.TARGET)
		if raw_target is Target:
			target = raw_target
		elif raw_target is Task:
			task = raw_target

		# 2. Task ID lookup
		var task_id: String = payload.get(GameConstants.Payload.TASK_ID, "")
		if task == null and not task_id.is_empty() and manager:
			task = manager.get_task_by_id(task_id)

		# 3. Coordinate lookup
		if task == null and target == null:
			var target_coord: Vector2i = payload.get(GameConstants.Payload.TARGET_COORD, GameConstants.INVALID_COORD)
			if target_coord == GameConstants.INVALID_COORD:
				target_coord = payload.get(GameConstants.Payload.LOOT_COORD, GameConstants.INVALID_COORD)

			if target_coord != GameConstants.INVALID_COORD and manager:
				target = manager.get_target_at(target_coord)

		# 4. Target Index lookup (fallback for units)
		if task == null and target == null:
			var target_idx: int = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_INDEX)
			if target_idx != GameConstants.INVALID_INDEX and context.unit_manager:
				target = context.unit_manager.get_unit(target_idx)

	# 5. Resolve Target from Task if needed (prioritizing ID then Coords)
	if task and target == null and manager:
		if not task.target_id.is_empty():
			target = manager.get_target_by_id(task.target_id)
		if target == null and task.target_coord != GameConstants.INVALID_COORD:
			target = manager.get_target_at(task.target_coord)

	# 5. Fallback search: Find task for target if only target is known
	if task == null and manager and is_instance_valid(target):
		task = find_task_for_target(manager, target, required_event, faction)

	# 6. Validation: event type match
	if task and not required_event.is_empty() and task.event_type != required_event:
		task = null

	var is_narrative := task != null
	var resolution_mode := "NARRATIVE" if is_narrative else "INCIDENTAL"

	var result := TaskResolutionResult.new()
	result.task = task
	result.target = target
	result.location = target as Location
	result.loot = target as Loot
	result.unit = target as Unit
	result.is_narrative = is_narrative
	result.resolution_mode = resolution_mode
	return result

## Helper to find a specific task for a target and event type.
static func find_task_for_target(
	manager: TaskManager,
	target: Target,
	required_event: String,
	faction: int = GameConstants.INVALID_INDEX
) -> Task:
	if not manager or not is_instance_valid(target):
		return null

	var tasks: Array[Task] = manager.get_active_tasks_for_target(target, faction)
	for task in tasks:
		if task and task.event_type == required_event:
			return task
	return null
