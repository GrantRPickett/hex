class_name AttackEvaluator
extends AIActionEvaluator

const AttackUnitCommand = preload("res://Gameplay/commands/attack_unit_command.gd")

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

	var unit_index := context.unit_manager.get_unit_index(unit)

	for enemy: Unit in near_enemies:
		var enemy_index := context.unit_manager.get_unit_index(enemy)
		var best_attr: int = unit.get_best_attribute_index()
		
		# Quality-based scoring
		var score := score_attack_base
		var combat_system := unit.get_combat_system()
		if combat_system:
			var quality = combat_system.get_attack_quality(unit, enemy, best_attr)
			score *= _get_quality_multiplier(quality)
			
		var action := AIAction.new(GameConstants.ActionType.ATTACK, score)
		action.command_id = GameConstants.Commands.CommandID.ATTACK
		action.command_payload = AttackUnitCommand.create_payload(unit_index, enemy_index, best_attr)
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
			var score: float = score_move_to_enemy - path.size()
			
			# Quality-based scoring for move-to-enemy
			var combat_system := unit.get_combat_system()
			if combat_system:
				var quality = combat_system.get_attack_quality(unit, target, best_attr)
				score *= _get_quality_multiplier(quality)
				
			var target_index := context.unit_manager.get_unit_index(target)
			var action := AIAction.new(GameConstants.ActionType.MOVE_TO_ENEMY, score)
			action.command_id = GameConstants.Commands.CommandID.ATTACK
			action.command_payload = AttackUnitCommand.create_payload(unit_index, target_index, best_attr)
			action.target_object = target
			action.path = path
			# Calculate move cost from path
			action.move_cost = path.size() # Simplified
			actions.append(action)

	# Fallback: if nothing found yet, try any reachable hex near to a hostile
	if actions.is_empty():
		var fallback := _fallback_enemy_action(unit, context, score_move_to_enemy, unit_index)
		if fallback:
			actions.append(fallback)

	return actions

# -- helpers -------------------------------------------------------------------

func _is_neutral(unit: Unit) -> bool:
	return unit.faction == GameConstants.Faction.NEUTRAL


func _fallback_enemy_action(unit: Unit, context: AIContext, score_move_to_enemy: float, unit_index: int) -> AIAction:
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
			var target_index := context.unit_manager.get_unit_index(target)
			var action := AIAction.new(GameConstants.ActionType.MOVE_TO_ENEMY, score_move_to_enemy * GameConstants.AI.RATIO_FALLBACK_ACTION)
			action.command_id = GameConstants.Commands.CommandID.ATTACK
			var best_attr: int = unit.get_best_attribute_index()
			action.command_payload = AttackUnitCommand.create_payload(unit_index, target_index, best_attr)
			action.target_object = target
			action.path = path
			action.move_cost = path.size()
			return action
	return null
