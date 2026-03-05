class_name ConfirmMoveCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.CONFIRM_MOVE

static func get_command_description() -> String:
	return "Confirm the current tentative move of the selected unit"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.GRID, GameConstants.Context.UNIT_MANAGER, GameConstants.Context.MOVE_CONTROLLER, GameConstants.Context.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if not unit or not unit.movement.has_tentative_move():
		return CommandResult.precondition_failed("No tentative move to confirm")

	context.move_controller.confirm_move()

	return CommandResult.success()
