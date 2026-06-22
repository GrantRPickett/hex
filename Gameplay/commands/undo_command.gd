class_name UndoCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.UNDO

static func create_payload() -> Dictionary:
	return {}

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER])

func execute(context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if CommandHistory.undo(context):
		return CommandResult.success()

	return CommandResult.failed("Nothing to undo")
