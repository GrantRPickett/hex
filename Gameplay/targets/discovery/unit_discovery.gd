class_name UnitDiscovery
extends RefCounted

## Generic unit discovery functions.
## These return units based on faction relationship to a source unit.

## Returns all units categorized by relationship to the source unit.
static func get_all_units(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.query:
		return {"enemies": [], "allies": [], "neutrals": []}

	var enemies = unit.query.get_hostile_units()
	var allies = unit.query.get_friendly_units()
	var neutrals = unit.query.get_neutral_units()
	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}

## Returns adjacent units categorized by relationship.
static func get_adjacent_units(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.query:
		return {"enemies": [], "allies": [], "neutrals": []}

	var hostiles = unit.query.get_hostile_units()
	var adjacent_hostiles = unit.query.get_adjacent_units(hostiles)

	var friendlies = unit.query.get_friendly_units()
	var adjacent_friendlies = unit.query.get_adjacent_units(friendlies)

	var neutral_units = unit.query.get_neutral_units()
	var adjacent_neutrals = unit.query.get_adjacent_units(neutral_units)

	return {
		"enemies": adjacent_hostiles,
		"allies": adjacent_friendlies,
		"neutrals": adjacent_neutrals
	}
