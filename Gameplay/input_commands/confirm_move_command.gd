class_name ConfirmMoveCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["grid", "unit_manager", "move_controller", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	context.move_controller.confirm_move()

	return CommandResult.success()
