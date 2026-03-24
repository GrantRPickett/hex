class_name TalkEvaluator
extends AIActionEvaluator

const TalkToUnitCommand = preload("res://Gameplay/commands/talk_to_unit_command.gd")

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if not is_instance_valid(unit):
		return []

	var profile = unit.get_combat_profile()
	var score_talk_base: float = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_TALK if profile else GameConstants.AI.SCORE_TALK_BASE
	score_talk_base *= GameConstants.AI.WEIGHT_UNOPPOSED
	var score_move_to_talk_base: float = float(profile.get_weight(&"objective")) * GameConstants.AI.MULTIPLIER_MOVE_TO_TALK if profile else GameConstants.AI.SCORE_MOVE_TO_TALK_BASE

	var actions: Array[AIAction] = []
	var dialogue_service := _resolve_dialogue_service(context)

	_find_talk_actions(unit, context, dialogue_service, actions, score_talk_base)
	_find_move_to_talk_actions(unit, context, dialogue_service, actions, score_move_to_talk_base)

	return actions

# -- private -------------------------------------------------------------------

func _resolve_dialogue_service(context: AIContext) -> DialogueActionService:
	var service: DialogueActionService = context.command_context.dialogue_action_service if context.command_context else null
	if service == null:
		service = PlayerActionManager.get_dialogue_service()
	return service

func _find_talk_actions(
		unit: Unit,
		context: AIContext,
		dialogue_service: DialogueActionService,
		actions: Array[AIAction],
		score_talk_base: float
) -> void:
	if not unit.res.has_action_available() or dialogue_service == null or context.unit_manager == null:
		return

	var unit_index := context.unit_manager.get_unit_index(unit)
	if unit_index == GameConstants.INVALID_INDEX:
		return

	var dialogue_actions: Array[PlayerAction] = []
	dialogue_service.append_dialogue_actions(dialogue_actions, unit, context.unit_manager)

	for action in dialogue_actions:
		if not action.available:
			continue

		var target_index := int(action.command_payload.get("target_index", GameConstants.INVALID_INDEX))
		if target_index < 0:
			continue

		var dialogue_id = action.command_payload.get("dialogue_id", "")
		if String(dialogue_id).is_empty():
			continue

		var initiator_index := int(action.command_payload.get("initiator_index", unit_index))

		var ai_action := AIAction.new(GameConstants.ActionType.TALK, score_talk_base)
		ai_action.command_id = GameConstants.Commands.CommandID.TALK
		ai_action.command_payload = TalkToUnitCommand.create_payload(initiator_index, target_index, dialogue_id)
		ai_action.target_object = context.unit_manager.get_unit(target_index)
		actions.append(ai_action)

func _find_move_to_talk_actions(
		unit: Unit,
		context: AIContext,
		dialogue_service: DialogueActionService,
		actions: Array[AIAction],
		score_move_to_talk_base: float
) -> void:
	if context.unit_manager == null or context.terrain_map == null:
		return

	var unit_index := context.unit_manager.get_unit_index(unit)
	var threatened_hexes: Dictionary = {}
	if unit.movement:
		threatened_hexes = unit.movement.get_threatened_hexes(
			context.unit_manager, context.terrain_map
		)

	var near_targets = context.get_near_units_categorized(unit)
	var near_units = near_targets["allies"] + near_targets["neutrals"] + near_targets["enemies"]

	for target in context.unit_manager.get_units():
		if target == null or target == unit:
			continue
		if not is_instance_valid(target) or target.is_dead:
			continue
		# Already near — the talk actions pass handles it
		if near_units.has(target):
			continue

		var has_dialogue := false
		if dialogue_service:
			var triggers = dialogue_service._trigger_manager.get_all_triggers() if dialogue_service._trigger_manager else []
			var active_flag = dialogue_service._active_flag
			has_dialogue = DialogueDiscovery.has_active_dialogue(unit, target, triggers, active_flag)

		# Only move to talk if there's a dialogue, or it's a Neutral unit (RPG flavour)
		if not has_dialogue and target.faction != GameConstants.Faction.NEUTRAL:
			continue

		var path := _find_path_to_near(unit, target.get_grid_location(), context, threatened_hexes)
		if path.is_empty():
			continue

		var score: float = score_move_to_talk_base - path.size()
		if has_dialogue:
			score += GameConstants.AI.DIALOGUE_PRIORITY_BONUS

		var target_index := context.unit_manager.get_unit_index(target)
		var ai_action := AIAction.new(GameConstants.ActionType.MOVE_TO_TALK, score)
		ai_action.command_id = GameConstants.Commands.CommandID.TALK
		# Payload placeholder until distance is closed
		ai_action.command_payload = TalkToUnitCommand.create_payload(unit_index, target_index, "")
		ai_action.target_object = target
		ai_action.path = path
		ai_action.move_cost = path.size()
		actions.append(ai_action)

func _find_path_to_near(
		unit: Unit,
		target_pos: Vector2i,
		context: AIContext,
		_threatened_hexes: Dictionary
) -> Array[Vector2i]:
	var best_path: Array[Vector2i] = []
	var best_score: int = GameConstants.MAX_DISTANCE
	for neighbor in context.terrain_map.get_neighbors(target_pos):
		if context.unit_manager.is_occupied(neighbor):
			continue
		var path := unit.movement.get_path_to_coord(neighbor, context.terrain_map)
		if not path.is_empty():
			var score := path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path
