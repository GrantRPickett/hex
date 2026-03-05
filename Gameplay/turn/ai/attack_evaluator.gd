class_name AttackEvaluator
extends AIActionEvaluator

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")

## Finds attack and move-to-enemy actions for the given unit.
## Priority:
##   - Adjacent enemy  → ACTION_ATTACK (high score)
##   - Reachable enemy → ACTION_MOVE_TO_ENEMY (score decreases with distance)
##   - Fallback        → closest reachable adjacent hex to any enemy


func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if _is_neutral(unit):
		return []

	var profile = unit.get_combat_profile()
	var score_attack_base = float(profile.get_weight(&"attack")) * GameConstants.AI.MULTIPLIER_ATTACK if profile else GameConstants.AI.SCORE_ATTACK_BASE
	score_attack_base *= GameConstants.AI.WEIGHT_OPPOSED
	var score_move_to_enemy = score_attack_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var adjacent_targets = _CombatDiscovery.get_adjacent_targets(unit)
	var adjacent_enemies = adjacent_targets["enemies"]

	# High-priority: attack an already-adjacent enemy
	for enemy in adjacent_enemies:
		actions.append(AIAction.new(GameConstants.AI.ACTION_ATTACK, enemy, [], score_attack_base))

	# Lower-priority: move toward any non-adjacent enemy
	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var all_enemies = all_targets["enemies"]
	for target in all_enemies:
		if adjacent_enemies.has(target):
			continue
		var path = _MapDiscovery.find_path_to_adjacent(unit, target.get_grid_location(), context.terrain_map, context.unit_manager)
		if not path.is_empty():
			var score: float = score_move_to_enemy - path.size()
			actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_ENEMY, target, path, score))

	# Fallback: if nothing found yet, try any reachable hex adjacent to a hostile
	if actions.is_empty():
		var fallback := _fallback_enemy_action(unit, context, score_move_to_enemy)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_neutral(unit: Unit) -> bool:
	return unit.faction == Unit.Faction.NEUTRAL


func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_enemy: float) -> AIAction:
	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var hostiles = all_targets["enemies"]
	for target in hostiles:
		if target == null:
			continue
		var path = _MapDiscovery.find_path_to_adjacent(unit, target.get_grid_location(), context.terrain_map, context.unit_manager)
		if not path.is_empty():
			return AIAction.new(GameConstants.AI.ACTION_MOVE_TO_ENEMY, target, path, score_move_to_enemy * GameConstants.AI.RATIO_FALLBACK_ACTION)
	return null
