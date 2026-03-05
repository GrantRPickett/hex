class_name ConvinceEvaluator
extends AIActionEvaluator

const _UnitDiscovery = preload("res://Gameplay/targets/discovery/unit_discovery.gd")
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")
const _MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")


func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	# Neutrals with no loyalty shouldn't initiate convincing (usually wildlife/passive)
	if unit.faction == Unit.Faction.NEUTRAL and unit.loyalty.neutral_loyalty == Unit.Faction.NEUTRAL:
		return []

	var actions: Array[AIAction] = []
	var profile = unit.get_combat_profile()
	var score_convince_base = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_CONVINCE if profile else GameConstants.AI.SCORE_CONVINCE_BASE
	score_convince_base *= GameConstants.AI.WEIGHT_UNOPPOSED

	var targets = _UnitDiscovery.get_adjacent_units(unit)
	var neutrals = targets["neutrals"]

	for n in neutrals:
		if _ConvinceDiscovery.is_convincable(n):
			actions.append(AIAction.new(GameConstants.AI.ACTION_CONVINCE, n, [], score_convince_base))

	# Move to convince
	var all_targets = _UnitDiscovery.get_all_units(unit)
	var all_neutrals = all_targets["neutrals"]
	for target in all_neutrals:
		if neutrals.has(target):
			continue
		if _ConvinceDiscovery.is_convincable(target):
			var path = _MapDiscovery.find_path_to_adjacent(unit, target.get_grid_location(), context.terrain_map, context.unit_manager)
			if not path.is_empty():
				var score: float = score_convince_base * GameConstants.AI.RATIO_MOVE_TO_TARGET - path.size()
				actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_CONVINCE, target, path, score))

	return actions
