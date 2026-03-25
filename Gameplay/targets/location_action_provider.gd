class_name LocationActionProvider
extends RefCounted

func append_location_action(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	var results: Dictionary = TargetDiscoveryService.get_categorized_locations(unit, reach)

	_add_task_summary_action(actions, unit, results.immediate_explore, results.reachable_explore, reach.lookup, results.target_to_task, GameConstants.ActionType.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
	_add_task_summary_action(actions, unit, results.immediate_visit, results.reachable_visit, reach.lookup, results.target_to_task, GameConstants.ActionType.VISIT, GameConstants.ActionIds.LOCATION_UNOPPOSED)

func _add_task_summary_action(actions: Array[PlayerAction], actor: Unit, immediate: Array[Location], reachable: Array[Location], reachable_lookup: Dictionary, target_to_task: Dictionary, action_type: GameConstants.ActionType, action_id: String) -> void:
	var imm_count: int = immediate.size()
	var reach_count: int = reachable.size()

	if imm_count > 0 or reach_count > 0:
		var action: PlayerAction = PlayerAction.create(action_type, action_id)
		action.actor = actor
		action.ui_label_params = {
			"near": imm_count,
			"far": reach_count
		}
		action.available = imm_count > 0 or reach_count > 0
		action.needs_attribute = true
		action.target_to_task = target_to_task

		if imm_count > 0:
			action.target_object = immediate[0]
			action.command_payload[GameConstants.Payload.INTERACT_TARGET_COORD] = immediate[0].get_grid_location()
			action.targets.assign(immediate)

		if reach_count > 0:
			ActionUtility.set_reachable_info(action, reachable, reachable_lookup)
			if imm_count == 0:
				var loc: Location = reachable[0]
				action.target_object = loc
				action.command_payload[GameConstants.Payload.INTERACT_TARGET_COORD] = loc.get_grid_location()
			
			for l in reachable:
				action.reachable_targets.append(l)

		actions.append(action)
