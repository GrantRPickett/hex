class_name ConfirmMoveCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.CONFIRM_MOVE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.GRID, GameConstants.ContextKeys.UNIT_MANAGER, GameConstants.ContextKeys.MOVE_CONTROLLER, GameConstants.ContextKeys.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit: Unit = context.get_selected_unit()
	if not unit or not unit.movement.has_tentative_move():
		return CommandResult.precondition_failed("No tentative move to confirm")

	context.move_controller.confirm_move()

	return CommandResult.success()
