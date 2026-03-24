class_name AidAllyEvaluator
extends AIActionEvaluator

const AidAllyCommand = preload("res://Gameplay/commands/aid_ally_command.gd")

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if not unit.res.has_action_available():
		return []

	var profile = unit.get_combat_profile()
	var score_aid_ally_base: float = float(profile.get_weight(&"protect_ally")) * GameConstants.AI.MULTIPLIER_AID_ALLY if profile else GameConstants.AI.SCORE_AID_ALLY_BASE
	score_aid_ally_base *= GameConstants.AI.WEIGHT_UNOPPOSED

	var actions: Array[AIAction] = []
	var near_targets = context.get_near_units_categorized(unit)
	var near_allies = near_targets["allies"]

	var unit_index := context.unit_manager.get_unit_index(unit)

	for ally in near_allies:
		if not (ally is Unit):
			continue

		# Only aid if the ally has an action available to actually use the buff
		if not ally.res.has_action_available():
			continue

		# Check if the ally is in a position to use the buff (near to an enemy)
		var ally_targets = context.get_near_units_categorized(ally)
		var ally_enemies = ally_targets["enemies"]

		# If the ally has no one to attack, aiding them is much lower priority
		var need_multiplier: float = 1.0
		if ally_enemies.is_empty():
			need_multiplier = 0.25 # Significant penalty if they have no immediate target

		# Diminishing returns if already buffed
		var existing_buff: int = 0
		for b in ally.aid_buffs: existing_buff += b
		if existing_buff > 0:
			need_multiplier *= 0.5

		var score: float = score_aid_ally_base * need_multiplier
		var best_attr = _get_best_aid_attribute(unit)

		var ally_index := context.unit_manager.get_unit_index(ally)
		var action := AIAction.new(GameConstants.ActionType.AID, score)
		action.command_id = GameConstants.Commands.CommandID.AID
		action.command_payload = AidAllyCommand.create_payload(unit_index, ally_index, best_attr)
		action.target_object = ally
		actions.append(action)

	return actions

func _get_best_aid_attribute(unit: Unit) -> int:
	var best_val := -1
	var best_attr := 0

	for pair in GameConstants.Combat.COMBAT_ATTRIBUTE_PAIRS:
		var attr0: GameConstants.AttributeIndex = pair[0]
		var attr1: GameConstants.AttributeIndex = pair[1]
		var val_a: int = unit.get_attribute(attr0)
		var val_b: int = unit.get_attribute(attr1)
		var pair_max: int = max(val_a, val_b)
		if pair_max > best_val:
			best_val = pair_max
			best_attr = int(attr0) if val_a >= val_b else int(attr1)

	return best_attr
