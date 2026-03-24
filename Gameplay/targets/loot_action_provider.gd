class_name LootActionProvider
extends RefCounted

func append_loot_action(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	var results := TargetDiscoveryService.get_categorized_loot(unit, reach)
	var split_loot: Dictionary = results.split_loot
	var target_to_task: Dictionary = results.target_to_task
	
	_add_categorized_loot_actions(actions, split_loot, reach.lookup, target_to_task)

func _add_categorized_loot_actions(actions: Array[PlayerAction], split_loot: Dictionary, reachable_lookup: Dictionary, target_to_task: Dictionary) -> void:
	if split_loot.immediate_trapped or not split_loot.reachable_trapped.is_empty():
		_add_loot_action(actions, split_loot.immediate_trapped, split_loot.reachable_trapped, reachable_lookup, GameConstants.ActionType.TRAPPED, GameConstants.ActionIds.ITEM_OPPOSED, target_to_task)
		
	if split_loot.immediate_gather or not split_loot.reachable_gather.is_empty():
		_add_loot_action(actions, split_loot.immediate_gather, split_loot.reachable_gather, reachable_lookup, GameConstants.ActionType.GATHER, GameConstants.ActionIds.ITEM_UNOPPOSED, target_to_task)

func _add_loot_action(actions: Array[PlayerAction], immediate_loot: Loot, reachable_loot: Array, reachable_lookup: Dictionary, action_type: GameConstants.ActionType, action_id: String, target_to_task: Dictionary = {}) -> void:
	var loot_immediate_count := 1 if immediate_loot else 0
	var loot_reachable_count: int = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var loot_action := PlayerAction.create(action_type, action_id)
		loot_action.ui_label_params = {"near": loot_immediate_count, "far": loot_reachable_count, "imm_label": "near"}
		loot_action.available = loot_immediate_count > 0 or loot_reachable_count > 0
		loot_action.needs_attribute = true
		loot_action.target_to_task = target_to_task
		
		if loot_immediate_count > 0:
			loot_action.target_object = immediate_loot
			loot_action.command_payload[GameConstants.Payload.INTERACT_TARGET_COORD] = immediate_loot.get_grid_location()
			loot_action.targets = [immediate_loot] as Array[Target]

		if loot_reachable_count > 0:
			ActionUtility.set_reachable_info(loot_action, reachable_loot, reachable_lookup)
			if loot_immediate_count == 0:
				loot_action.target_object = reachable_loot[0]
				loot_action.command_payload[GameConstants.Payload.INTERACT_TARGET_COORD] = reachable_loot[0].get_grid_location()
				loot_action.targets = reachable_loot.duplicate() as Array[Target]
			else:
				loot_action.targets.append_array(reachable_loot)

		actions.append(loot_action)
