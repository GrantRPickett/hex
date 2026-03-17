class_name TaskActionProvider
extends RefCounted

func append_task_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void:
	var task_manager: TaskManager = unit.get_task_manager()
	if not task_manager:
		return

	var immediate_tasks: Array[Task] = TargetDiscoveryService.get_immediate_tasks(unit, action_origin, task_manager)
	for task in immediate_tasks:
		# Skip tasks handled by specialized providers
		if _is_location_task(task):
			continue
		if _is_loot_task(task):
			continue
		if _is_unit_task(task):
			continue

		_add_task_action(actions, task, action_origin, unit)

func _is_location_task(task: Task) -> bool:
	if task.target_kind == &"location":
		return true
	return task.event_type == GameConstants.TaskEvents.VISIT or task.event_type == GameConstants.TaskEvents.EXPLORE

func _is_loot_task(task: Task) -> bool:
	if task.target_kind == &"item":
		return true
	return task.event_type == GameConstants.TaskEvents.LOOT or task.event_type == GameConstants.TaskEvents.TRAPPED

func _is_unit_task(task: Task) -> bool:
	return task.target_kind == &"unit" or task.event_type == GameConstants.TaskEvents.ATTACK or task.event_type == GameConstants.TaskEvents.CONVINCE

func _add_task_action(actions: Array[UnitAction], task: Task, action_origin: Vector2i, unit: Unit = null) -> void:
	if not unit:
		return

	var action = UnitAction.create(UnitAction.Type.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
	action.label_params = {"task": task.title}
	action.interact_target_coord = action_origin
	action.task_id = String(task.id)
	action.needs_attribute = true
	actions.append(action)
