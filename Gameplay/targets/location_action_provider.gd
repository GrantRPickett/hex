class_name LocationActionProvider
extends RefCounted

const _MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")
const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_location_action(actions: Array[UnitAction], _unit: Unit, action_origin: Vector2i) -> void:
	var task_manager = _unit.get_task_manager()
	if not task_manager:
		return

	var location = _MapDiscovery.get_location_at(task_manager, action_origin)
	if not location:
		return

	# Determine if there is an active task for this location
	var active_tasks = _TaskDiscovery.get_active_tasks(task_manager)
	var matching_task: Task = null

	for task in active_tasks:
		if task.target_id == location.loc_name or task.target_coord == action_origin:
			matching_task = task
			break

	if not matching_task:
		return

	var is_opposed = (matching_task.event_type == GameConstants.TaskEvents.EXPLORE or matching_task.event_type == GameConstants.TaskEvents.INTERACT)

	if is_opposed:
		# Opposed explore action
		var action = UnitAction.create(UnitAction.Type.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
		action.label_params = {"location": location.loc_name}
		action.target = location
		action.interact_target_coord = action_origin
		action.task_id = String(matching_task.id)
		action.needs_attribute = true
		actions.append(action)
	else:
		# Unopposed visit action
		var action = UnitAction.create(UnitAction.Type.VISIT, GameConstants.ActionIds.LOCATION_UNOPPOSED)
		action.label_params = {"location": location.loc_name}
		action.target = location
		action.interact_target_coord = action_origin
		action.task_id = String(matching_task.id)
		actions.append(action)
