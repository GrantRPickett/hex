class_name LootActionProvider
extends RefCounted

const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")

func append_loot_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var immediate_loot := _find_immediate_loot(unit, action_origin)
	var reachable_loot := _find_reachable_loot(unit, reachable_coords, reachable_lookup, immediate_loot)
	_add_loot_action(actions, immediate_loot, reachable_loot)

func _find_immediate_loot(unit: Unit, action_origin: Vector2i) -> Node:
	return _LootDiscovery.get_immediate_loot(unit, action_origin, unit.get_loot_manager())

func _find_reachable_loot(unit: Unit, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, immediate_loot: Node) -> Array:
	var reachable_loot: Array = []
	if reachable_coords.size() <= 1:
		return reachable_loot

	var potential_targets = _LootDiscovery.get_potential_loot_targets(unit, unit.get_loot_manager(), immediate_loot)
	for target in potential_targets:
		if reachable_lookup.has(target.coord):
			reachable_loot.append(target.item)
	return reachable_loot

func _add_loot_action(actions: Array[Dictionary], immediate_loot: Node, reachable_loot: Array) -> void:
	var loot_immediate_count = 1 if immediate_loot else 0
	var loot_reachable_count = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var is_immediate_trapped = immediate_loot and immediate_loot.get("is_trapped")
		var is_first_reachable_trapped = loot_reachable_count > 0 and reachable_loot[0].get("is_trapped")

		# According to OpenSpec:
		# "loot" (internal) / "gather" (player-facing) for safe items, "trapped" for trapped items
		var action_type = "trapped" if is_immediate_trapped or (loot_immediate_count == 0 and is_first_reachable_trapped) else GameConstants.Interactions.GATHER

		var action_id = GameConstants.ActionIds.ITEM_OPPOSED if action_type == "trapped" else GameConstants.ActionIds.ITEM_UNOPPOSED

		var loot_action: Dictionary = {
			"type": action_type,
			"action_id": action_id,
			"label_params": {"adjacent": loot_immediate_count, "reachable": loot_reachable_count, "imm_label": "here"},
			"available": loot_immediate_count > 0
		}
		if loot_immediate_count > 0:
			loot_action["target"] = immediate_loot
		if loot_reachable_count > 0:
			loot_action["reachable"] = true
			loot_action["reachable_targets"] = reachable_loot
		actions.append(loot_action)
