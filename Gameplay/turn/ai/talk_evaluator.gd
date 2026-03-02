class_name TalkEvaluator
extends AIActionEvaluator

## Finds talk and move-to-talk actions for the given unit.
## Uses the DialogueActionService (via command context) to discover active
## dialogue triggers that this unit can initiate or respond to.
##
## Priority:
##   - Dialogue partner is adjacent          → ACTION_TALK (high score)
##   - Dialogue partner is reachable         → ACTION_MOVE_TO_TALK
##   - Any adjacent Neutral unit (RPG feel)  → ACTION_MOVE_TO_TALK (lower score)

const ACTION_TALK := &"talk"
const ACTION_MOVE_TO_TALK := &"move_to_talk"

const SCORE_TALK_BASE := 110.0
const SCORE_MOVE_TO_TALK_BASE := 60.0
const DIALOGUE_PRIORITY_BONUS := 50.0

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if not is_instance_valid(unit):
		return []

	var profile = unit.get_combat_profile()
	var score_talk_base = float(profile.get_weight(&"objective")) * 22.0 if profile else SCORE_TALK_BASE
	var score_move_to_talk_base = float(profile.get_weight(&"objective")) * 12.0 if profile else SCORE_MOVE_TO_TALK_BASE

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
	if not unit.has_action_available() or dialogue_service == null or context.unit_manager == null:
		return

	var unit_index := context.unit_manager.get_unit_index(unit)
	if unit_index == -1:
		return

	var dialogue_actions: Array[Dictionary] = []
	dialogue_service.append_dialogue_actions(dialogue_actions, unit, context.unit_manager)

	for action_dict in dialogue_actions:
		if not action_dict.get("available", true):
			continue
		var target_index := int(action_dict.get("target_index", -1))
		if target_index < 0:
			continue
		var dialogue_id_value = action_dict.get("dialogue_id", StringName(""))
		var dialogue_id: StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)
		if String(dialogue_id).is_empty():
			continue
		var initiator_index := int(action_dict.get("initiator_index", unit_index))
		if initiator_index < 0:
			initiator_index = unit_index
		var payload := {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		actions.append(AIAction.new(ACTION_TALK, payload, [], score_talk_base))

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
	if unit.movement_behavior:
		threatened_hexes = unit.movement_behavior.get_threatened_hexes(
			context.unit_manager, context.terrain_map
		)

	for target in context.unit_manager.get_units():
		if target == null or target == unit:
			continue
		if not is_instance_valid(target) or target.is_dead:
			continue
		# Already adjacent — the talk actions pass handles it
		if unit.get_grid_location().distance_to(target.get_grid_location()) <= 1.5:
			continue

		var has_dialogue := false
		if dialogue_service:
			has_dialogue = dialogue_service.has_active_dialogue_with(unit, target)

		# Only move to talk if there's a dialogue, or it's a Neutral unit (RPG flavour)
		if not has_dialogue and target.faction != Unit.Faction.NEUTRAL:
			continue

		var path := _find_path_to_adjacent(unit, target.get_grid_location(), context, threatened_hexes)
		if path.is_empty():
			continue

		var score: float = score_move_to_talk_base - path.size()
		if has_dialogue:
			score += DIALOGUE_PRIORITY_BONUS
		actions.append(AIAction.new(ACTION_MOVE_TO_TALK, target, path, score))

func _find_path_to_adjacent(
		unit: Unit,
		target_pos: Vector2i,
		context: AIContext,
		_threatened_hexes: Dictionary
) -> Array:
	var best_path: Array = []
	var best_score: int = 9999
	for neighbor in context.terrain_map.get_neighbors(target_pos):
		if context.unit_manager.is_occupied(neighbor):
			continue
		var path := unit.get_path_to_coord(neighbor, context.terrain_map)
		if not path.is_empty():
			var score := path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path
