class_name CancelMoveCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.CANCEL_MOVE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.GRID, GameConstants.Context.UNIT_MANAGER, GameConstants.Context.MOVE_CONTROLLER, GameConstants.Context.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if unit == null or not unit.movement.has_tentative_move():
		return CommandResult.precondition_failed("No move to cancel")

	context.move_controller.cancel_move()

	return CommandResult.success()
