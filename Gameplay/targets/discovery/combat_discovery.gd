class_name CombatDiscovery
extends RefCounted

## Returns a dictionary containing 'enemies', 'allies', and 'neutrals' that are adjacent to the unit.
static func get_adjacent_targets(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not is_instance_valid(unit.query):
		return {"enemies": [], "allies": [], "neutrals": []}

	var adjacent = unit.query.get_adjacent_units_categorized()
	var enemies: Array = []
	var allies: Array = []
	var neutrals: Array = []

	for ally in adjacent["allies"]:
		if ally != unit:
			allies.append(ally)

	for enemy in adjacent["enemies"]:
		if is_instance_valid(enemy) and enemy.willpower > 0:
			enemies.append(enemy)

	for neutral in adjacent["neutrals"]:
		if neutral != unit:
			neutrals.append(neutral)

	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}

## Returns all known combat targets for the given unit.
static func get_all_targets(unit: Unit) -> Dictionary:
	if not is_instance_valid(unit) or not is_instance_valid(unit.query):
		return {"enemies": [], "allies": [], "neutrals": []}
	
	var all_units = unit.query.get_all_units_categorized()
	var enemies: Array = []
	var allies: Array = []
	var neutrals: Array = []

	for ally in all_units["allies"]:
		if ally != unit and is_instance_valid(ally) and ally.willpower > 0:
			allies.append(ally)

	for enemy in all_units["enemies"]:
		if is_instance_valid(enemy) and enemy.willpower > 0:
			enemies.append(enemy)

	for neutral in all_units["neutrals"]:
		if neutral != unit and is_instance_valid(neutral) and neutral.willpower > 0:
			neutrals.append(neutral)

	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}
