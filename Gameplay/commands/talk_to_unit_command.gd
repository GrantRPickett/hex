class_name TalkToUnitCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.TALK

static func get_command_description() -> String:
	return "Initiate a dialogue with an adjacent unit"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER, GameConstants.Context.DIALOGUE_ACTION_SERVICE])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if payload == null or not payload is Dictionary:
		return CommandResult.invalid_payload("Payload must be a Dictionary.")

	var initiator_idx = payload.get(GameConstants.Payload.INITIATOR_INDEX, GameConstants.INVALID_INDEX)
	var target_idx = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_INDEX)
	var dialogue_id = payload.get(GameConstants.Payload.DIALOGUE_ID, "")

	if initiator_idx == GameConstants.INVALID_INDEX or target_idx == GameConstants.INVALID_INDEX or dialogue_id == "":
		return CommandResult.invalid_payload("Missing initiator_index, target_index, or dialogue_id.")

	if context.dialogue_action_service == null:
		return CommandResult.invalid_context(["dialogue_action_service"])

	return context.dialogue_action_service.start_dialogue(dialogue_id, initiator_idx, target_idx)
