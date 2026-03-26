class_name LocationService
extends RefCounted

var _task_manager: TaskManager
var _unit_manager: UnitManager

func setup(task_manager: TaskManager, unit_manager: UnitManager = null) -> void:
	_task_manager = task_manager
	_unit_manager = unit_manager

func get_all_locations_data() -> Array[Dictionary]:
	var locations_data: Array[Dictionary] = []
	if not _task_manager:
		return locations_data

	for loc in _task_manager.get_all_locations():
		if is_instance_valid(loc):
			locations_data.append(_transform_location_to_data(loc))
	return locations_data

func get_location_data_at_coordinate(coord: Vector2i) -> Dictionary:
	if not _task_manager:
		return {}

	var loc: Node = _task_manager.get_location_at(coord)
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
		var tasks: Array = _task_manager.get_active_tasks_for_target(loc, GameConstants.Faction.PLAYER)
		if not tasks.is_empty():
			data["task"] = {
				"title": tasks[0].title,
				"description": tasks[0].description,
				"current_effort": tasks[0].current_effort,
				"effort_required": tasks[0].effort_required,
				"id": String(tasks[0].id)
			}

			# Check if any unit is currently on this location to perform the task
			if is_instance_valid(_unit_manager):
				var unit_idx: int = _unit_manager.index_of_unit_at(loc.coord)
				if unit_idx != -1:
					var unit: Unit = _unit_manager.get_unit(unit_idx)
					if is_instance_valid(unit) and _unit_manager.is_player_controlled(unit_idx):
						data["can_explore"] = true

	return data

func visit_location(location: Location, unit: Unit) -> bool:
	if location == null or unit == null:
		return false

	GameLogger.debug(GameLogger.Category.MAP, "[LocationService] Unit %s visiting location: %s" % [unit.unit_name, location.loc_name])
	location.interact(unit, {"is_task": false, "type": GameConstants.Interactions.VISIT})
	return true

func explore_location(location: Location, unit: Unit, task: Task, attribute: String = "", precomputed_results: Dictionary = {}) -> bool:
	if location == null or unit == null or task == null:
		return false

	var coord: Vector2i = location.get_grid_location()
	if not task.can_be_worked_on_by(unit, coord):
		GameLogger.debug(GameLogger.Category.MAP, "[LocationService] Exploration at %s cannot be performed by unit %s" % [coord, unit.unit_name])
		return false

	var context = {
		"is_task": true,
		"task_id": String(task.id),
		"type": GameConstants.Interactions.EXPLORE,
		"attribute": attribute,
		"forecast": precomputed_results
	}

	GameLogger.debug(GameLogger.Category.MAP, "[LocationService] Unit %s exploring %s (Task: %s, Attribute: %s)" % [unit.unit_name, location.loc_name, task.id, attribute])
	location.interact(unit, context)
	return true

func create_memento() -> Dictionary:
	var locs = get_all_locations_data()
	return {"locations": locs}

func restore_from_memento(_memento: Dictionary) -> void:
	# Restoration is mostly handled by TaskManager/Objective re-spawning locations
	pass
