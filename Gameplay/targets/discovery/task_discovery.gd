class_name TaskDiscovery
extends RefCounted

## Returns all active tasks from the current objective stage.
static func get_active_tasks(task_manager) -> Array:
	if not is_instance_valid(task_manager):
		return []

	var active_objective = task_manager.get_active_objective()
	if not active_objective or not active_objective.current_stage:
		return []

	var tasks = []
	for task in active_objective.current_stage.active_tasks:
		if is_instance_valid(task) and task.status == Task.Status.ACTIVE:
			tasks.append(task)
	return tasks

## Returns tasks at the given location that the unit can work on.
static func get_immediate_tasks(unit: Unit, coord: Vector2i, task_manager) -> Array:
	if not is_instance_valid(task_manager):
		return []

	var active_tasks = get_active_tasks(task_manager)
	var immediate = []
	for task in active_tasks:
		if task.event_type == "interact" or task.event_type == "explore":
			if task.target_coord != Vector2i(-999, -999) and task.target_coord != coord:
				continue
			
			# If the task relies on an ID, verify the target at the coord matches it
			if not task.target_id.is_empty():
				var location = task_manager.get_location_at(coord)
				if location == null or task.target_id != location.loc_name:
					# It might be a loot task, but typically IDs are for locations.
					continue

			if is_instance_valid(unit) and task.can_be_worked_on_by(unit, coord):
				immediate.append(task)

	return immediate
