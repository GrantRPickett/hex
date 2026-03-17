class_name ConvinceEvaluator
extends AIActionEvaluator

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	# Neutrals with no loyalty shouldn't initiate convincing (usually wildlife/passive)
	if unit.faction == GameConstants.Faction.NEUTRAL and unit.loyalty.neutral_loyalty == GameConstants.Faction.NEUTRAL:
		return []

	var actions: Array[AIAction] = []
	var profile: CombatPriorityProfile = unit.get_combat_profile()
	var score_convince_base: float = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_CONVINCE if profile else GameConstants.AI.SCORE_CONVINCE_BASE
	score_convince_base *= GameConstants.AI.WEIGHT_UNOPPOSED

	if not is_instance_valid(unit.query):
		return []

	var targets: Dictionary = unit.query.get_near_units_categorized()
	var neutrals: Array[Unit] = []
	if targets.has("neutrals"):
		neutrals.assign(targets["neutrals"])

	for n: Unit in neutrals:
		if TargetDiscoveryService.is_convincable(n):
			actions.append(AIAction.new(GameConstants.AI.ACTION_CONVINCE, n, [], score_convince_base))

	# Move to convince
	if not is_instance_valid(unit.query):
		return actions

	var all_targets: Dictionary = unit.query.get_all_units_categorized()
	var all_neutrals: Array[Unit] = []
	if all_targets.has("neutrals"):
		all_neutrals.assign(all_targets["neutrals"])

	for target: Unit in all_neutrals:
		if neutrals.has(target):
			continue
		if TargetDiscoveryService.is_convincable(target):
			var path: Array[Vector2i] = unit.movement.get_path_to_near(target.get_grid_location(), context.terrain_map, context.unit_manager)
			if not path.is_empty():
				var score: float = score_convince_base * GameConstants.AI.RATIO_MOVE_TO_TARGET - path.size()
				actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_CONVINCE, target, path, score))

	return actions
