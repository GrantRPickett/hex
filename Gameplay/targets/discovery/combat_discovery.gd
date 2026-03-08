class_name CombatDiscovery
extends RefCounted

const UnitDiscovery = preload("res://Gameplay/targets/discovery/unit_discovery.gd")

## Returns a dictionary containing 'enemies', 'allies', and 'neutrals' that are adjacent to the unit.
static func get_adjacent_targets(unit: Unit) -> Dictionary:
	var adjacent = UnitDiscovery.get_adjacent_units(unit)
	var enemies: Array = []
	var allies: Array = []
	var neutrals: Array = []

	for ally in adjacent["allies"]:
		if ally != unit:
			allies.append(ally)

	for enemy in adjacent["enemies"]:
		if enemy.willpower > 0:
			enemies.append(enemy)

	for neutral in adjacent["neutrals"]:
		if neutral != unit:
			neutrals.append(neutral)

	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}

## Returns all known combat targets for the given unit.
static func get_all_targets(unit: Unit) -> Dictionary:
	return UnitDiscovery.get_all_units(unit)
