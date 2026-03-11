class_name LootDiscovery
extends RefCounted

## Unified target discovery for Loot. Used by both AI Evaluators and Human Action Providers.

## Returns the loot item at the given coordinate if the unit can loot it.
static func get_immediate_loot(unit: Node, coord: Vector2i, loot_manager: Node) -> Node:
	if not is_instance_valid(loot_manager):
		return null
	var loot = loot_manager.get_loot_at(coord) if loot_manager.has_method("get_loot_at") else null
	if loot and is_instance_valid(unit) and can_be_looted_by(unit, loot):
		return loot
	return null

## Returns true if the unit is close enough to the loot to interact with it.
static func can_be_looted_by(unit: Node, loot: Node, interaction_range: float = 1.5) -> bool:
	if not is_instance_valid(unit) or not is_instance_valid(loot):
		return false
	if not unit.has_method("distance_to_target"):
		return false
	return unit.distance_to_target(loot) <= interaction_range

## Returns all loot items and their coords that the unit could potentially loot.
static func get_potential_loot_targets(unit: Node, loot_manager: Node, immediate_loot: Node = null) -> Array[Dictionary]:
	var reachable_loot: Array[Dictionary] = []
	if not is_instance_valid(loot_manager):
		return reachable_loot

	var loot_count = loot_manager.get_loot_count() if loot_manager.has_method("get_loot_count") else 0
	for loot_index in range(loot_count):
		var loot_item = loot_manager.get_loot(loot_index) if loot_manager.has_method("get_loot") else null
		if not is_instance_valid(loot_item) or loot_item == immediate_loot:
			continue
		if is_instance_valid(unit) and not can_be_looted_by(unit, loot_item):
			continue
		var coord = loot_manager.get_coord(loot_index) if loot_manager.has_method("get_coord") else GameConstants.INVALID_COORD
		if coord == GameConstants.INVALID_COORD:
			continue
		reachable_loot.append({"item": loot_item, "coord": coord})

	return reachable_loot
