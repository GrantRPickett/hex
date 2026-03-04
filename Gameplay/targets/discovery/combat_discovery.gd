class_name CombatDiscovery
extends RefCounted

## Returns a dictionary containing 'enemies', 'allies', and 'neutrals' that are adjacent to the unit.
static func get_adjacent_targets(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.query:
		return {"enemies": [], "allies": [], "neutrals": []}

	var enemies: Array = []
	var allies: Array = []
	var neutrals: Array = []

	var friendlies = unit.query.get_friendly_units()
	var adjacent_friendlies = unit.query.get_adjacent_units(friendlies)
	for ally in adjacent_friendlies:
		if ally == unit: continue
		if ally.willpower < ally.max_willpower:
			allies.append(ally)

	var hostiles = unit.query.get_hostile_units()
	var adjacent_hostiles = unit.query.get_adjacent_units(hostiles)
	for enemy in adjacent_hostiles:
		if enemy.willpower > 0:
			enemies.append(enemy)

	var neutral_units = unit.query.get_neutral_units()
	var adjacent_neutrals = unit.query.get_adjacent_units(neutral_units)
	for neutral in adjacent_neutrals:
		if neutral != unit:
			neutrals.append(neutral)

	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}

## Returns all known combat targets for the given unit.
static func get_all_targets(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not unit.query:
		return {"enemies": [], "allies": [], "neutrals": []}

	var enemies = unit.query.get_hostile_units()
	var allies = unit.query.get_friendly_units()
	var neutrals = unit.query.get_neutral_units()
	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}
