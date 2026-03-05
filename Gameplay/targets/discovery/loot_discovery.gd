class_name LootDiscovery
extends RefCounted

## Unified target discovery for Loot. Used by both AI Evaluators and Human Action Providers.

## Returns the loot item at the given coordinate if the unit can loot it.
static func get_immediate_loot(unit: Unit, coord: Vector2i, loot_manager) -> Node:
	if not is_instance_valid(loot_manager):
		return null
	var loot = loot_manager.get_loot_at(coord)
	if loot and is_instance_valid(unit) and loot.can_be_looted_by(unit):
		return loot
	return null

## Returns all loot items and their coords that the unit could potentially loot.
static func get_potential_loot_targets(unit: Unit, loot_manager, immediate_loot: Node = null) -> Array[Dictionary]:
	var reachable_loot: Array[Dictionary] = []
	if not is_instance_valid(loot_manager):
		return reachable_loot

	var loot_count = loot_manager.get_loot_count()
	for loot_index in range(loot_count):
		var loot_item = loot_manager.get_loot(loot_index)
		if not is_instance_valid(loot_item) or loot_item == immediate_loot:
			continue
		if is_instance_valid(unit) and not loot_item.can_be_looted_by(unit):
			continue
		var coord = loot_manager.get_coord(loot_index)
		if coord == GameConstants.INVALID_COORD:
			continue
		reachable_loot.append({"item": loot_item, "coord": coord})

	return reachable_loot
