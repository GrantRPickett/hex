class_name UndoCommand
extends GameCommand

static func get_command_name() -> String:
	return "undo"

static func get_command_description() -> String:
	return "Undo the last interaction"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager"])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if CommandHistory.undo(context):
		return CommandResult.success()

	return CommandResult.failed("Nothing to undo")