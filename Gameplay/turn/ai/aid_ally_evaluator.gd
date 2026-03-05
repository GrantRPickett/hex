class_name AidAllyEvaluator
extends AIActionEvaluator

const CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")

## Finds aid-ally actions for the given unit.
## Considers adjacent friendly units that have lost willpower.
## Score is boosted by how much willpower the ally is missing.


func evaluate(unit: Unit, _context: AIContext) -> Array[AIAction]:
	if not unit.res.has_action_available():
		return []

	var profile = unit.get_combat_profile()
	var score_aid_ally_base = float(profile.get_weight(&"protect_ally")) * GameConstants.AI.MULTIPLIER_AID_ALLY if profile else GameConstants.AI.SCORE_AID_ALLY_BASE
	score_aid_ally_base *= GameConstants.AI.WEIGHT_UNOPPOSED

	var actions: Array[AIAction] = []
	var adjacent_targets = CombatDiscovery.get_adjacent_targets(unit)
	var adjacent_allies = adjacent_targets["allies"]

	for ally in adjacent_allies:
		var score: float = score_aid_ally_base + (ally.max_willpower - ally.willpower)
		actions.append(AIAction.new(GameConstants.AI.ACTION_AID_ALLY, ally, [], score))

	return actions
