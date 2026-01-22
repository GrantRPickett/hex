class_name CancelMoveCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["grid", "unit_manager", "move_controller", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if unit == null or not unit.has_tentative_move():
		return CommandResult.precondition_failed("No move to cancel")

	context.move_controller.cancel_move()

	return CommandResult.success()
