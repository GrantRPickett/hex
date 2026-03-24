class_name TalkToUnitCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TALK


static func create_payload(initiator_index: int, target_index: int, dialogue_id: String) -> Dictionary:
	return {
		GameConstants.Payload.INITIATOR_INDEX: initiator_index,
		GameConstants.Payload.TARGET_INDEX: target_index,
		GameConstants.Payload.DIALOGUE_ID: dialogue_id
	}

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER, GameConstants.ContextKeys.DIALOGUE_ACTION_SERVICE])

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
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
