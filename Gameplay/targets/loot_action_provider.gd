class_name LootActionProvider
extends RefCounted

const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")

func append_loot_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var immediate_loot := _find_immediate_loot(unit, action_origin)
	var reachable_loot := _find_reachable_loot(unit, reachable_coords, reachable_lookup, immediate_loot)
	
	# Split into Trapped and Non-trapped
	var immediate_trapped: Node = null
	var immediate_gather: Node = null
	
	if immediate_loot:
		if bool(immediate_loot.get("is_trapped")):
			immediate_trapped = immediate_loot
		else:
			immediate_gather = immediate_loot
			
	var reachable_trapped: Array = []
	var reachable_gather: Array = []
	
	for loot in reachable_loot:
		if bool(loot.get("is_trapped")):
			reachable_trapped.append(loot)
		else:
			reachable_gather.append(loot)
			
	# Add discrete actions
	if immediate_trapped or not reachable_trapped.is_empty():
		_add_loot_action(actions, immediate_trapped, reachable_trapped, UnitAction.Type.TRAPPED, GameConstants.ActionIds.ITEM_OPPOSED)
		
	if immediate_gather or not reachable_gather.is_empty():
		_add_loot_action(actions, immediate_gather, reachable_gather, UnitAction.Type.GATHER, GameConstants.ActionIds.ITEM_UNOPPOSED)

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

func _add_loot_action(actions: Array[UnitAction], immediate_loot: Node, reachable_loot: Array, action_type: UnitAction.Type, action_id: String) -> void:
	var loot_immediate_count = 1 if immediate_loot else 0
	var loot_reachable_count = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var loot_action = UnitAction.create(action_type, action_id)
		loot_action.label_params = {"near": loot_immediate_count, "far": loot_reachable_count, "imm_label": "near"}
		loot_action.available = loot_immediate_count > 0 or loot_reachable_count > 0
		loot_action.needs_attribute = true # Loot actions need targets/submenus
		
		if loot_immediate_count > 0:
			loot_action.target = immediate_loot
		if loot_reachable_count > 0:
			loot_action.reachable_targets = reachable_loot
		actions.append(loot_action)
