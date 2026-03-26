class_name AttackEvaluator
extends AIActionEvaluator

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if _is_neutral(unit):
		return []

	var profile := unit.get_combat_profile()
	var score_attack_base: float = float(profile.get_weight(&"fight")) * GameConstants.AI.MULTIPLIER_FIGHT if profile else GameConstants.AI.SCORE_FIGHT_BASE
	score_attack_base *= GameConstants.AI.WEIGHT_OPPOSED
	var score_move_to_fight := score_attack_base * GameConstants.AI.RATIO_MOVE_TO_TARGET

	var actions: Array[AIAction] = []
	var near_targets: Dictionary = unit.query.get_near_units_categorized()
	var near_enemies: Array = near_targets.get("enemies", [])

	var unit_index := context.unit_manager.get_unit_index(unit)

	for enemy: Unit in near_enemies:
		var best_attr: int = unit.get_best_attribute_index()

		# Quality-based scoring
		var score := score_attack_base
		var combat_system := unit.get_combat_system()
		if combat_system:
			var quality = combat_system.get_attack_quality(unit, enemy, best_attr)
			score *= _get_quality_multiplier(quality)

		var action := AIAction.new(GameConstants.ActionType.FIGHT, score)
		action.command_id = GameConstants.Commands.CommandID.INTERACT
		action.command_payload = PerformInteractionCommand.create_payload(unit_index, enemy.get_grid_location(), GameConstants.Interactions.FIGHT, {"attribute_index": best_attr})
		action.target_object = enemy
		actions.append(action)

	# Lower-priority: move toward any non-near enemy
	var discovery_results := _discover_nearby(unit, context, [TargetDiscoveryService.UNIT])
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
			var best_attr: int = unit.get_best_attribute_index()
			var score: float = score_move_to_fight - path.size()

			# Quality-based scoring for move-to-fight
			var combat_system := unit.get_combat_system()
			if combat_system:
				var quality = combat_system.get_attack_quality(unit, target, best_attr)
				score *= _get_quality_multiplier(quality)

			var action := AIAction.new(GameConstants.ActionType.MOVE_TO_FIGHT, score)
			action.command_id = GameConstants.Commands.CommandID.INTERACT
			action.command_payload = PerformInteractionCommand.create_payload(unit_index, target.get_grid_location(), GameConstants.Interactions.FIGHT, {"attribute_index": best_attr})
			action.target_object = target
			action.path = path
			action.move_cost = path.size()
			actions.append(action)

	# Fallback: if nothing found yet, try any reachable hex near to a hostile
	if actions.is_empty():
		var fallback := _fallback_enemy_action(unit, context, score_move_to_fight, unit_index)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_neutral(unit: Unit) -> bool:
	return unit.faction == GameConstants.Faction.NEUTRAL

func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_fight: float, unit_index: int) -> AIAction:
	var discovery_results := _discover_nearby(unit, context, [TargetDiscoveryService.UNIT])
	var units_result = discovery_results.get(TargetDiscoveryService.UNIT, {})
	var hostiles: Array = []
	if units_result is Dictionary:
		hostiles = units_result.get("enemies", [])
	elif units_result is Array:
		hostiles = units_result

	for target: Unit in hostiles:
		if target == null:
			continue
		var path: Array[Vector2i] = unit.movement.get_path_to_near(target.get_grid_location(), context.terrain_map, context.unit_manager)
		if not path.is_empty():
			var action := AIAction.new(GameConstants.ActionType.MOVE_TO_FIGHT, score_move_to_fight * GameConstants.AI.RATIO_FALLBACK_ACTION)
			action.command_id = GameConstants.Commands.CommandID.INTERACT
			var best_attr: int = unit.get_best_attribute_index()
			action.command_payload = PerformInteractionCommand.create_payload(unit_index, target.get_grid_location(), GameConstants.Interactions.FIGHT, {"attribute_index": best_attr})
			action.target_object = target
			action.path = path
			action.move_cost = path.size()
			return action
	return null
