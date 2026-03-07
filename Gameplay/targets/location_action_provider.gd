class_name LocationActionProvider
extends RefCounted

const _MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")
const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_location_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var task_manager = unit.get_task_manager()
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

	var is_opposed = (matching_task.event_type == GameConstants.TaskEvents.EXPLORE or matching_task.event_type == GameConstants.TaskEvents.TARGET_INTERACTION)

	if is_opposed:
		# Opposed explore action
		actions.append({
			"type": GameConstants.Interactions.EXPLORE,
			"action_id": GameConstants.ActionIds.LOCATION_OPPOSED,
			"label_params": {"location": location.loc_name},
			"available": true,
			"target": location,
			"interact_target_coord": action_origin,
			"task_id": String(matching_task.id),
			"needs_attribute": true,
		})
	else:
		# Unopposed visit action
		actions.append({
			"type": GameConstants.Interactions.VISIT,
			"action_id": GameConstants.ActionIds.LOCATION_UNOPPOSED,
			"label_params": {"location": location.loc_name},
			"available": true,
			"target": location,
			"interact_target_coord": action_origin,
			"task_id": String(matching_task.id),
		})

func _select_best_task_attribute_name(attrs) -> String:
	if attrs == null:
		return GameConstants.Attributes.GRIT
	var best_name := GameConstants.Attributes.GRIT
	var best_value := -INF
	for attr_name in Target.COMBAT_ATTRIBUTE_NAMES:
		var attr_value = attrs.get_attribute(attr_name)
		if attr_value > best_value:
			best_value = attr_value
			best_name = attr_name
	return best_name
