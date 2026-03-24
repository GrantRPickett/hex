class_name SelectIndexCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.SELECT_INDEX

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER])

static func create_payload(index: int) -> Dictionary:
	return {
		GameConstants.Payload.INDEX: index
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if not payload.has(GameConstants.Payload.INDEX):
		return CommandResult.invalid_payload("Index required in payload")

	var unit_manager := context.unit_manager
	var index: int = int(payload.get(GameConstants.Payload.INDEX, GameConstants.INVALID_INDEX))
	unit_manager.select_index(index)
	if unit_manager.get_selected_index() != index:
		return CommandResult.precondition_failed("Cannot select unit at index %d" % index)

	return CommandResult.success()
