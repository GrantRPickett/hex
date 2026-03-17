class_name LootEvaluator
extends AIActionEvaluator

## Finds loot and move-to-loot actions for the given unit.
## Priority:
##   - near loot	  → ACTION_LOOT (high score)
##   - Reachable loot → ACTION_MOVE_TO_LOOT (score decreases with distance)

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var score_loot_base: float = float(profile.get_weight(&"loot")) * GameConstants.AI.MULTIPLIER_LOOT if profile else GameConstants.AI.SCORE_LOOT_BASE
	var score_move_to_loot: float = score_loot_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var start_pos: Vector2i = unit.get_grid_location()

	# 1. Nearby loot (O(1) neighbor check usually, but for AI we might want a small radius)
	var discovery_results: Dictionary = TargetDiscoveryService.discover_nearby(start_pos, GameConstants.AI.AI_DISCOVERY_RADIUS, [TargetDiscoveryService.LOOT], {
		"loot_manager": context.loot_manager
	})
	var potential_targets: Array[Loot] = []
	if discovery_results.has(TargetDiscoveryService.LOOT):
		potential_targets.assign(discovery_results[TargetDiscoveryService.LOOT])
	
	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)

	for loot: Loot in potential_targets:
		var target_pos: Vector2i = loot.get_grid_location()
		var dist: int = HexLib.get_distance(start_pos, target_pos)
		
		# If it's already adjacent, offer loot action
		if dist <= GameConstants.AI.GRID_ADJACENCY_THRESHOLD:
			var score: float = score_loot_base
			if threatened_hexes.has(target_pos):
				score -= GameConstants.AI.THREAT_PENALTY
			actions.append(AIAction.new(GameConstants.AI.ACTION_LOOT, loot, [], score))
		else:
			# Otherwise, offer move action if reachable
			var path: Array[Vector2i] = unit.movement.get_path_to_near(target_pos, context.terrain_map, context.unit_manager)
			if not path.is_empty():
				var end_pos: Vector2i = path.back()
				var is_threatened: bool = threatened_hexes.has(end_pos)
				var score: float = score_move_to_loot - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)
				actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_LOOT, loot, path, score))

	return actions

# -- helpers -------------------------------------------------------------------

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	if unit.movement:
		return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}
