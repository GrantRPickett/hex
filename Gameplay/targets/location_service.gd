class_name LocationService
extends RefCounted

var _task_manager: TaskManager

func setup(task_manager: TaskManager) -> void:
	_task_manager = task_manager

func get_all_locations_data() -> Array[Dictionary]:
	var locations_data: Array[Dictionary] = []
	if not _task_manager:
		return locations_data

	for loc in _task_manager._locations:
		if is_instance_valid(loc):
			locations_data.append(_transform_location_to_data(loc))
	return locations_data

func get_location_data_at_coordinate(coord: Vector2i) -> Dictionary:
	if not _task_manager:
		return {}

	var loc = _task_manager.get_location_at(coord)
	if is_instance_valid(loc):
		return _transform_location_to_data(loc)

	return {}

func _transform_location_to_data(loc: Location) -> Dictionary:
	var data = {
		"name": loc.loc_name,
		"description": loc.description,
		"coord": loc.coord,
		"exploration_state": loc.exploration_state,
		"stat_boosts": {}
	}

	if _task_manager:
		var tasks = _task_manager.get_active_tasks_for_target(loc)
		if not tasks.is_empty():
			data["task"] = {
				"title": tasks[0].title,
				"description": tasks[0].description,
				"current_effort": tasks[0].current_effort,
				"effort_required": tasks[0].effort_required
			}

	return data

func create_memento() -> Dictionary:
	var locs = get_all_locations_data()
	return {"locations": locs}

func restore_from_memento(_memento: Dictionary) -> void:
	# Restoration is mostly handled by TaskManager/Objective re-spawning locations
	pass
