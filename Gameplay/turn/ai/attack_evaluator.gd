class_name AttackEvaluator
extends AIActionEvaluator

## Finds attack and move-to-enemy actions for the given unit.
## Priority:
##   - near enemy  → ACTION_ATTACK (high score)
##   - Reachable enemy → ACTION_MOVE_TO_ENEMY (score decreases with distance)
##   - Fallback		→ closest reachable near hex to any enemy


func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if _is_neutral(unit):
		return []

	var profile := unit.get_combat_profile()
	var score_attack_base: float = float(profile.get_weight(&"attack")) * GameConstants.AI.MULTIPLIER_ATTACK if profile else GameConstants.AI.SCORE_ATTACK_BASE
	score_attack_base *= GameConstants.AI.WEIGHT_OPPOSED
	var score_move_to_enemy := score_attack_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var near_targets: Dictionary = unit.query.get_near_units_categorized()
	var near_enemies: Array = near_targets["enemies"]

	# High-priority: attack an already-near enemy
	for enemy: Unit in near_enemies:
		actions.append(AIAction.new(GameConstants.AI.ACTION_ATTACK, enemy, [], score_attack_base))

	# Lower-priority: move toward any non-near enemy
	var discovery_results := TargetDiscoveryService.discover_nearby(unit.get_grid_location(), GameConstants.AI.AI_DISCOVERY_RADIUS, [TargetDiscoveryService.UNIT], {
		"unit_manager": context.unit_manager,
		"source_unit": unit
	})
	var units_result = discovery_results.get(TargetDiscoveryService.UNIT, {})
	var all_enemies: Array = []
	if units_result is Dictionary:
		all_enemies = units_result.get("enemies", [])
	elif units_result is Array:
		all_enemies = units_result
	
	for target: Unit in all_enemies:
		if near_enemies.has(target):
			continue
		var path: Array[Vector2i] = unit.movement.get_path_to_near(target.get_grid_location(), context.terrain_map, context.unit_manager)
		if not path.is_empty():
			var score: float = score_move_to_enemy - path.size()
			actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_ENEMY, target, path, score))

	# Fallback: if nothing found yet, try any reachable hex near to a hostile
	if actions.is_empty():
		var fallback := _fallback_enemy_action(unit, context, score_move_to_enemy)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_neutral(unit: Unit) -> bool:
	return unit.faction == GameConstants.Faction.NEUTRAL


func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_enemy: float) -> AIAction:
	var all_targets: Dictionary = unit.query.get_all_units_categorized()
	var hostiles: Array = all_targets["enemies"]
	for target: Unit in hostiles:
		if target == null:
			continue
		var path: Array[Vector2i] = unit.movement.get_path_to_near(target.get_grid_location(), context.terrain_map, context.unit_manager)
		if not path.is_empty():
			return AIAction.new(GameConstants.AI.ACTION_MOVE_TO_ENEMY, target, path, score_move_to_enemy * GameConstants.AI.RATIO_FALLBACK_ACTION)
	return null
