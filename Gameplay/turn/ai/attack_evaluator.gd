class_name AttackEvaluator
extends AIActionEvaluator

const CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")

## Finds attack and move-to-enemy actions for the given unit.
## Priority:
##   - Adjacent enemy  → ACTION_ATTACK (high score)
##   - Reachable enemy → ACTION_MOVE_TO_ENEMY (score decreases with distance)
##   - Fallback        → closest reachable adjacent hex to any enemy

const ACTION_ATTACK := &"attack"
const ACTION_MOVE_TO_ENEMY := &"move_to_enemy"

const SCORE_ATTACK_BASE := 100.0
const SCORE_MOVE_TO_ENEMY := 50.0

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if _is_neutral(unit):
		return []

	var profile = unit.get_combat_profile()
	var score_attack_base = float(profile.get_weight(&"attack")) * 10.0
	var score_move_to_enemy = score_attack_base * 0.5

	var actions: Array[AIAction] = []
	var adjacent_targets = CombatDiscovery.get_adjacent_targets(unit)
	var adjacent_enemies = adjacent_targets["enemies"]

	# High-priority: attack an already-adjacent enemy
	for enemy in adjacent_enemies:
		actions.append(AIAction.new(ACTION_ATTACK, enemy, [], score_attack_base))

	# Lower-priority: move toward any non-adjacent enemy
	var all_targets = CombatDiscovery.get_all_targets(unit)
	var all_enemies = all_targets["enemies"]
	for target in all_enemies:
		if adjacent_enemies.has(target):
			continue
		var path = _find_path_to_adjacent(unit, target.get_grid_location(), context)
		if not path.is_empty():
			var score: float = score_move_to_enemy - path.size()
			actions.append(AIAction.new(ACTION_MOVE_TO_ENEMY, target, path, score))

	# Fallback: if nothing found yet, try any reachable hex adjacent to a hostile
	if actions.is_empty():
		var fallback := _fallback_enemy_action(unit, context, score_move_to_enemy)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_neutral(unit: Unit) -> bool:
	return unit.faction == Unit.Faction.NEUTRAL

func _find_path_to_adjacent(unit: Unit, target_pos: Vector2i, context: AIContext) -> Array:
	var best_path: Array = []
	var best_score: int = 9999
	if context.terrain_map == null:
		return best_path
	for neighbor in context.terrain_map.get_neighbors(target_pos):
		if context.unit_manager.is_occupied(neighbor):
			continue
		var path = unit.movement.get_path_to_coord(neighbor, context.terrain_map)
		if not path.is_empty():
			var score = path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path

func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_enemy: float) -> AIAction:
	var all_targets = CombatDiscovery.get_all_targets(unit)
	var hostiles = all_targets["enemies"]
	for target in hostiles:
		if target == null:
			continue
		var path = _find_path_to_adjacent(unit, target.get_grid_location(), context)
		if not path.is_empty():
			return AIAction.new(ACTION_MOVE_TO_ENEMY, target, path, score_move_to_enemy * 0.1)
	return null
