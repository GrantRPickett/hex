class_name LootActionProvider
extends RefCounted

func append_loot_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var immediate_loot := _find_immediate_loot(unit, action_origin)
	var reachable_loot := _find_reachable_loot(unit, reachable_coords, reachable_lookup, immediate_loot)
	_add_loot_action(actions, immediate_loot, reachable_loot)

func _find_immediate_loot(unit: Unit, action_origin: Vector2i) -> Node:
	var loot_manager = unit.get_loot_manager()
	if not loot_manager:
		return null
	var loot = loot_manager.get_loot_at(action_origin)
	if loot and loot.can_be_looted_by(unit):
		return loot
	return null

func _find_reachable_loot(unit: Unit, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, immediate_loot: Node) -> Array:
	var reachable_loot: Array = []
	var loot_manager = unit.get_loot_manager()
	if not loot_manager or reachable_coords.size() <= 1:
		return reachable_loot

	var loot_count = loot_manager.get_loot_count()
	for loot_index in range(loot_count):
		var loot_item = loot_manager.get_loot(loot_index)
		if loot_item == null or loot_item == immediate_loot:
			continue
		if not loot_item.can_be_looted_by(unit):
			continue
		var loot_coord = loot_manager.get_coord(loot_index)
		if reachable_lookup.has(loot_coord):
			reachable_loot.append(loot_item)
	return reachable_loot

func _add_loot_action(actions: Array[Dictionary], immediate_loot: Node, reachable_loot: Array) -> void:
	var loot_immediate_count = 1 if immediate_loot else 0
	var loot_reachable_count = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var has_trap = immediate_loot and immediate_loot.get("is_trapped")
		var is_first_reachable_trapped = loot_reachable_count > 0 and reachable_loot[0].get("is_trapped")
		var base_label = "Pick up Loot"
		var hint = "Move onto the loot to pick it up."

		# Update UI labels if the immediate or primary target is trapped
		if has_trap:
			base_label = "Investigate Trap"
		elif is_first_reachable_trapped and loot_immediate_count == 0:
			base_label = "Investigate Trap"
			hint = "Move to investigate the trapped item."

		var loot_action: Dictionary = {
			"type": "loot",
			"label": ActionLabelFormatter.format(base_label, loot_immediate_count, loot_reachable_count),
			"available": loot_immediate_count > 0
		}
		if loot_immediate_count > 0:
			loot_action["target"] = immediate_loot
		if loot_reachable_count > 0:
			loot_action["reachable"] = true
			loot_action["reachable_targets"] = reachable_loot
			loot_action["hint"] = hint
		actions.append(loot_action)
