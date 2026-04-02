class_name LocationService
extends RefCounted

var _unit_manager: UnitManager
var locs: Dictionary[Vector2i, Location] = {}

func setup(unit_manager: UnitManager = null) -> void:
	_unit_manager = unit_manager

func get_location_at(coord: Vector2i) -> Location:
	return locs.get(coord)

func _transform_location_to_data(loc: Location) -> Dictionary:
	var data = {
		"name": loc.loc_name,
		"description": loc.description,
		"coord": loc.coord,
		"is_explored": loc.is_explored,
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

func restore_from_memento(_memento: Dictionary) -> void:
	locs = _memento["locations"]
	pass

func reset() -> void:
	locs = {}
	pass
