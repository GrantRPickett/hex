class_name ConvinceDiscovery
extends RefCounted

## Unified discovery for "Convince" interactions.
## Used by AI evaluators and manual action providers to identify units
## that can be persuaded instead of fought.

## Returns true if the unit meets the criteria for being convinced.
static func is_convincable(unit: Unit) -> bool:
	if not is_instance_valid(unit) or unit.faction != Unit.Faction.NEUTRAL:
		return false

	# If loyalty is locked, it cannot be changed anymore.
	if unit.loyalty.loyalty_locked:
		return false

	# Loyal neutrals (inclination to PLAYER or ENEMY) must be fought (opposed).
	if unit.loyalty.neutral_loyalty != Unit.Faction.NEUTRAL or \
	   not unit.neutral_can_be_persuaded or \
	   unit.loyalty_type == GameConstants.Loyalty.STATIC:
		return false

	return true


## Splits a set of targets into those that must be fought and those that can be convinced.
static func split_targets(enemies: Array) -> Dictionary:
	var fight: Array[Unit] = []
	var convince: Array[Unit] = []

	for enemy in enemies:
		if is_convincable(enemy):
			convince.append(enemy)
		else:
			fight.append(enemy)

	return {
		"fight": fight,
		"convince": convince
	}
