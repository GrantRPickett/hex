class_name AidAllyEvaluator
extends AIActionEvaluator

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")

## Finds aid-ally actions for the given unit.
## Considers adjacent friendly units for encouragement.
## Score is based on protecting/buffing allies.


func evaluate(unit: Unit, _context: AIContext) -> Array[AIAction]:
	if not unit.res.has_action_available():
		return []

	var profile = unit.get_combat_profile()
	var score_aid_ally_base = float(profile.get_weight(&"protect_ally")) * GameConstants.AI.MULTIPLIER_AID_ALLY if profile else GameConstants.AI.SCORE_AID_ALLY_BASE
	score_aid_ally_base *= GameConstants.AI.WEIGHT_UNOPPOSED

	var actions: Array[AIAction] = []
	var adjacent_targets = _CombatDiscovery.get_adjacent_targets(unit)
	var adjacent_allies = adjacent_targets["allies"]

	for ally in adjacent_allies:
		var score: float = score_aid_ally_base
		var best_attr = _get_best_aid_attribute(unit)
		actions.append(AIAction.new(
			GameConstants.AI.ACTION_AID_ALLY, 
			{"unit": ally, "attribute_index": best_attr}, 
			[], 
			score
		))

	return actions

func _get_best_aid_attribute(unit: Unit) -> int:
	var best_val = -1
	var best_idx = 0
	
	# Check all 3 pairs
	for i in range(3):
		var pair = CombatSystem.PAIRS[i]
		var val_a = unit.get_attribute(pair[0])
		var val_b = unit.get_attribute(pair[1])
		var max_stat = max(val_a, val_b)
		if max_stat > best_val:
			best_val = max_stat
			best_idx = i * 2 # Return first attr of the pair
			
	return best_idx
