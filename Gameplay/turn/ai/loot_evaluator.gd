class_name LootEvaluator
extends AIActionEvaluator

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var score_gather_base: float = float(profile.get_weight(&"loot")) * GameConstants.AI.MULTIPLIER_GATHER if profile else GameConstants.AI.SCORE_GATHER_BASE
	var score_trapped_base: float = float(profile.get_weight(&"loot")) * GameConstants.AI.MULTIPLIER_TRAPPED if profile else GameConstants.AI.SCORE_TRAPPED_BASE
	var score_move_to_loot: float = score_gather_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var start_pos: Vector2i = unit.get_grid_location()
	var unit_index := context.unit_manager.get_unit_index(unit)

	# 1. Nearby loot
	var discovery_results: Dictionary = _discover_nearby(unit, context, [TargetDiscoveryService.LOOT])
	var potential_targets: Array[Loot] = []
	if discovery_results.has(TargetDiscoveryService.LOOT):
		potential_targets.assign(discovery_results[TargetDiscoveryService.LOOT])

	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)

	for loot: Loot in potential_targets:
		var target_pos: Vector2i = loot.get_grid_location()
		var dist: int = HexLib.get_distance(start_pos, target_pos)

		var quality_multiplier := GameConstants.AI.QUALITY_MULTIPLIER_SUCCESS
		var is_trapped := false
		var combat_system := unit.get_combat_system()
		var task_manager := context.task_manager
		if combat_system and task_manager:
			var task = task_manager.get_task_for_target(loot)
			if task:
				var quality = combat_system.get_task_quality(unit, loot, task)
				quality_multiplier = _get_quality_multiplier(quality)
				is_trapped = task.is_opposed

		if dist <= GameConstants.AI.GRID_ADJACENCY_THRESHOLD:
			var score: float = (score_trapped_base if is_trapped else score_gather_base) * quality_multiplier
			if threatened_hexes.has(target_pos):
				score -= GameConstants.AI.THREAT_PENALTY

			var action := AIAction.new(GameConstants.ActionType.TRAPPED if is_trapped else GameConstants.ActionType.GATHER, score)
			action.command_id = GameConstants.Commands.CommandID.INTERACT
			action.command_payload = PerformInteractionCommand.create_payload(unit_index, target_pos, GameConstants.Interactions.TRAPPED if is_trapped else GameConstants.Interactions.GATHER)
			action.target_object = loot
			actions.append(action)
		else:
			# Otherwise, offer move action if reachable
			var path: Array[Vector2i] = unit.movement.get_path_to_near(target_pos, context.terrain_map, context.unit_manager)
			if not path.is_empty():
				var end_pos: Vector2i = path.back()
				var is_threatened: bool = threatened_hexes.has(end_pos)
				var score: float = (score_move_to_loot * quality_multiplier) - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)

				var move_type = GameConstants.ActionType.MOVE_TO_TRAPPED if is_trapped else GameConstants.ActionType.MOVE_TO_GATHER
				var inter_type = GameConstants.Interactions.TRAPPED if is_trapped else GameConstants.Interactions.GATHER

				var action := AIAction.new(move_type, score)
				action.command_id = GameConstants.Commands.CommandID.INTERACT
				action.command_payload = PerformInteractionCommand.create_payload(unit_index, target_pos, inter_type)
				action.target_object = loot
				action.path = path
				action.move_cost = path.size()
				actions.append(action)

	return actions

# -- helpers -------------------------------------------------------------------

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	if unit.movement:
		return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}
