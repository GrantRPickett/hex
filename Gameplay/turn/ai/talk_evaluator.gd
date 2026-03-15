class_name TalkEvaluator
extends AIActionEvaluator

const DialogueDiscovery = preload("res://Gameplay/targets/discovery/dialogue_discovery.gd")

## Finds talk and move-to-talk actions for the given unit.
## Uses the DialogueActionService (via command context) to discover active
## dialogue triggers that this unit can initiate or respond to.
##
## Priority:
##   - Dialogue partner is near		  → ACTION_TALK (high score)
##   - Dialogue partner is reachable		 → GameConstants.AI.ACTION_MOVE_TO_TALK
##   - Any near Neutral unit (RPG feel)  → ACTION_MOVE_TO_TALK (lower score)


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
		service = UnitActionManager.get_dialogue_service()
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

	var dialogue_actions: Array[UnitAction] = []
	dialogue_service.append_dialogue_actions(dialogue_actions, unit, context.unit_manager)

	for action in dialogue_actions:
		if not action.available:
			continue
		var target_index := int(action.payload.get("target_index", GameConstants.INVALID_INDEX))
		if target_index < 0:
			continue
		var dialogue_id_value = action.payload.get("dialogue_id", StringName(""))
		var dialogue_id: StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)
		if String(dialogue_id).is_empty():
			continue
		var initiator_index := int(action.payload.get("initiator_index", unit_index))
		if initiator_index < 0:
			initiator_index = unit_index
		var payload := {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		actions.append(AIAction.new(GameConstants.AI.ACTION_TALK, payload, [], score_talk_base))

func _find_move_to_talk_actions(
		unit: Unit,
		context: AIContext,
		dialogue_service: DialogueActionService,
		actions: Array[AIAction],
		score_move_to_talk_base: float
) -> void:
	if context.unit_manager == null or context.terrain_map == null:
		return

	var threatened_hexes: Dictionary = {}
	if unit.movement:
		threatened_hexes = unit.movement.get_threatened_hexes(
			context.unit_manager, context.terrain_map
		)

	for target in context.unit_manager.get_units():
		if target == null or target == unit:
			continue
		if not is_instance_valid(target) or target.is_dead:
			continue
		# Already near — the talk actions pass handles it
		if unit.get_grid_location().distance_to(target.get_grid_location()) <= GameConstants.AI.GRID_ADJACENCY_THRESHOLD:
			continue

		var has_dialogue := false
		if dialogue_service:
			var triggers = dialogue_service._trigger_manager.get_all_triggers() if dialogue_service._trigger_manager else []
			var active_flag = dialogue_service._active_flag
			has_dialogue = DialogueDiscovery.has_active_dialogue(unit, target, triggers, active_flag)

		# Only move to talk if there's a dialogue, or it's a Neutral unit (RPG flavour)
		if not has_dialogue and target.faction != Unit.Faction.NEUTRAL:
			continue

		var path := _find_path_to_near(unit, target.get_grid_location(), context, threatened_hexes)
		if path.is_empty():
			continue

		var score: float = score_move_to_talk_base - path.size()
		if has_dialogue:
			score += GameConstants.AI.DIALOGUE_PRIORITY_BONUS
		actions.append(AIAction.new(GameConstants.AI.ACTION_MOVE_TO_TALK, target, path, score))

func _find_path_to_near(
		unit: Unit,
		target_pos: Vector2i,
		context: AIContext,
		_threatened_hexes: Dictionary
) -> Array:
	var best_path: Array = []
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
