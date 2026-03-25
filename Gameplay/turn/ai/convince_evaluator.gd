class_name ConvinceEvaluator
extends AIActionEvaluator

const ConvinceUnitCommand = preload("res://Gameplay/commands/convince_unit_command.gd")

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

	var unit_index := context.unit_manager.get_unit_index(unit)
	var targets: Dictionary = unit.query.get_near_units_categorized()
	var neutrals: Array[Unit] = []
	if targets.has("neutrals"):
		neutrals.assign(targets["neutrals"])

	for n: Unit in neutrals:
		if TargetDiscoveryService.is_convincable(n):
			var n_index := context.unit_manager.get_unit_index(n)
			var score := score_convince_base
			
			var combat_system := unit.get_combat_system()
			if combat_system:
				var best_attr := unit.get_best_attribute_index()
				var quality = combat_system.get_attack_quality(unit, n, best_attr, true)
				score *= _get_quality_multiplier(quality)
				
			var action := AIAction.new(GameConstants.ActionType.CONVINCE, score)
			action.command_id = GameConstants.Commands.CommandID.CONVINCE
			action.command_payload = ConvinceUnitCommand.create_payload(unit_index, n_index)
			action.target_object = n
			actions.append(action)

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
				var score := score_convince_base * GameConstants.AI.RATIO_MOVE_TO_TARGET
				
				var combat_system := unit.get_combat_system()
				if combat_system:
					var best_attr := unit.get_best_attribute_index()
					var quality = combat_system.get_attack_quality(unit, target, best_attr, true)
					score *= _get_quality_multiplier(quality)
				
				score -= path.size()
				
				var target_index := context.unit_manager.get_unit_index(target)
				var action := AIAction.new(GameConstants.ActionType.MOVE_TO_CONVINCE, score)
				action.command_id = GameConstants.Commands.CommandID.CONVINCE
				action.command_payload = ConvinceUnitCommand.create_payload(unit_index, target_index)
				action.target_object = target
				action.path = path
				action.move_cost = path.size()
				actions.append(action)

	return actions
