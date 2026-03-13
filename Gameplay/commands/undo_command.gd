class_name UndoCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.UNDO

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if CommandHistory.undo(context):
		return CommandResult.success()

	return CommandResult.failed("Nothing to undo")
