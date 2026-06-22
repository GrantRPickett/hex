class_name LocationService
extends RefCounted

var _unit_manager: UnitManager
var locs: Dictionary[Vector2i, Location] = {}

func setup(unit_manager: UnitManager = null) -> void:
	_unit_manager = unit_manager

func get_location_at(coord: Vector2i) -> Location:
	return locs.get(coord)

func visit_location(loc: Location, unit: Unit) -> void:
	if is_instance_valid(loc) and is_instance_valid(unit):
		loc.visit(unit.faction)

func explore_location(loc: Location, unit: Unit, _task: Task = null, _attr: String = "") -> bool:
	if is_instance_valid(loc) and is_instance_valid(unit):
		loc.explore()
		return true
	return false

func _transform_location_to_data(loc: Location) -> Dictionary:
	var data = {
		"name": loc.loc_name,
		"description": loc.description,
		"coord": loc.coord,
		"is_explored": not loc.is_hazard(),
		"stat_boosts": {}
	}

	# Check if any unit is currently on this location to perform the task
	if is_instance_valid(_unit_manager):
		var unit_idx: int = _unit_manager.index_of_unit_at(loc.coord)
		if unit_idx != -1:
			var unit: Unit = _unit_manager.get_unit(unit_idx)
			if is_instance_valid(unit) and _unit_manager.is_player_controlled(unit_idx):
				data["open"] = true

	return data

func create_memento() -> Dictionary:
	return {"locations": locs}

func get_all_locations() -> Array[Location]:
	var result: Array[Location] = []
	for loc in locs.values():
		if is_instance_valid(loc):
			result.append(loc)
	return result

func restore_from_memento(_memento: Dictionary) -> void:
	locs = _memento["locations"]
	pass

func reset() -> void:
	locs = {}
	pass
