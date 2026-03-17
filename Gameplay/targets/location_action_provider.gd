class_name LocationActionProvider
extends RefCounted

func append_location_action(actions: Array[UnitAction], unit: Unit, reach: ReachableState) -> void:
	var results : Dictionary = TargetDiscoveryService.get_categorized_locations(unit, reach)

	_add_task_summary_action(actions, results.immediate_explore, results.reachable_explore, reach.lookup, results.target_to_task, UnitAction.Type.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
	_add_task_summary_action(actions, results.immediate_visit, results.reachable_visit, reach.lookup, results.target_to_task, UnitAction.Type.VISIT, GameConstants.ActionIds.LOCATION_UNOPPOSED)

func _add_task_summary_action(actions: Array[UnitAction], immediate: Array[Location], reachable: Array[Location], reachable_lookup: Dictionary, target_to_task: Dictionary, action_type: UnitAction.Type, action_id: String) -> void:
	var imm_count: int = immediate.size()
	var reach_count: int = reachable.size()

	if imm_count > 0 or reach_count > 0:
		var action : UnitAction = UnitAction.create(action_type, action_id)
		action.label_params = {"near": imm_count, "far": reach_count, "imm_label": "near"}
		action.available = imm_count > 0 or reach_count > 0
		action.needs_attribute = true

		var all_targets: Array[Target] = []
		all_targets.append_array(immediate)
		all_targets.append_array(reachable)

		if not all_targets.is_empty():
			action.targets = all_targets
			action.target = all_targets[0]
			action.interact_target_coord = all_targets[0].get_grid_location()
			action.target_to_task = target_to_task

		if not reachable.is_empty():
			ActionUtility.set_reachable_info(action, reachable, reachable_lookup)

		actions.append(action)
