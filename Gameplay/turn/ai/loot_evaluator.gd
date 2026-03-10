class_name LootEvaluator
extends AIActionEvaluator

const LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")

## Finds loot and move-to-loot actions for the given unit.
## Priority:
##   - Loot at current position  → ACTION_LOOT (high score)
##   - Reachable loot coord	  → ACTION_MOVE_TO_LOOT (closer = better)


func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if context.loot_manager == null or context.terrain_map == null:
		return []

	var profile = unit.get_combat_profile()
	var score_loot_base = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_LOOT if profile else GameConstants.AI.SCORE_LOOT_BASE
	var score_move_to_loot = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_MOVE_TO_LOOT if profile else GameConstants.AI.SCORE_MOVE_TO_LOOT

	var actions: Array[AIAction] = []
	var start_pos := unit.get_grid_location()

	# Can we loot right now?
	if unit.res.has_action_available():
		var loot = context.loot_manager.get_loot_at(start_pos)
		if loot:
			var weight = GameConstants.AI.WEIGHT_OPPOSED if loot.is_trapped else GameConstants.AI.WEIGHT_UNOPPOSED
			actions.append(AIAction.new(GameConstants.AI.ACTION_LOOT, start_pos, [], score_loot_base * weight))

	# Find loot to move toward
	var threatened_hexes: Dictionary = _get_threatened_hexes(unit, context)
	var immediate_loot = LootDiscovery.get_immediate_loot(unit, start_pos, context.loot_manager)

	var potential_targets = LootDiscovery.get_potential_loot_targets(unit, context.loot_manager, immediate_loot)
	for target in potential_targets:
		var loot_item = target.item
		var loot_coord = target.coord
		var is_trapped = false
		if loot_item and "is_trapped" in loot_item:
			is_trapped = loot_item.is_trapped

		if context.unit_manager.is_occupied(loot_coord):
			continue

		var path = unit.movement.get_path_to_coord(loot_coord, context.terrain_map)
		if not path.is_empty():
			var is_threatened := threatened_hexes.has(loot_coord)
			var weight = GameConstants.AI.WEIGHT_OPPOSED if is_trapped else GameConstants.AI.WEIGHT_UNOPPOSED
			var score: float = (score_move_to_loot * weight) - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0.0)
			actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_LOOT, loot_item, path, score))

	return actions

# -- helpers -------------------------------------------------------------------

func _get_threatened_hexes(unit: Unit, context: AIContext) -> Dictionary:
	if unit.movement:
		return unit.movement.get_threatened_hexes(context.unit_manager, context.terrain_map)
	return {}
