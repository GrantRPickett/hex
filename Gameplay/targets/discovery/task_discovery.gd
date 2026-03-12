class_name TaskDiscovery
extends RefCounted

## Returns all active tasks from the current objective stage.
static func get_active_tasks(task_manager, faction: int = GameConstants.INVALID_INDEX) -> Array:
	if not is_instance_valid(task_manager):
		return []

	var active_objective = task_manager.get_active_objective()
	if not active_objective or not active_objective.current_stage:
		return []

	var tasks = []
	for task in active_objective.current_stage.active_tasks:
		if is_instance_valid(task) and task.status == Task.Status.ACTIVE:
			if faction == GameConstants.INVALID_INDEX or task.owning_faction == faction:
				tasks.append(task)
	return tasks

## Returns tasks at the given location that the unit can work on.
static func get_immediate_tasks(unit: Unit, coord: Vector2i, task_manager) -> Array:
	if not is_instance_valid(task_manager):
		return []

	var active_tasks = get_active_tasks(task_manager, unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX)
	var immediate = []
	for task in active_tasks:
		var is_relevant_type = (
			task.event_type == GameConstants.TaskEvents.EXPLORE or
			task.event_type == GameConstants.TaskEvents.VISIT or
			task.event_type == GameConstants.TaskEvents.LOOT or
			task.event_type == GameConstants.TaskEvents.INTERACT
		)

		if is_relevant_type:
			if task.target_coord != GameConstants.INVALID_COORD and task.target_coord != coord:
				continue

			# If the task relies on an ID, verify the target at the coord matches it
			if not task.target_id.is_empty():
				var target_id_matches = false
				var location = task_manager.get_location_at(coord)
				if location != null and task.target_id == location.loc_name:
					target_id_matches = true

				var loot_node = task_manager.get_loot_at(coord)
				if loot_node != null and task.target_id == "loot":
					target_id_matches = true

				if not target_id_matches:
					continue

			if is_instance_valid(unit) and task.can_be_worked_on_by(unit, coord):
				immediate.append(task)

	return immediate
