class_name JoyMoveCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.JOY_MOVE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER, 
		GameConstants.ContextKeys.HEX_NAVIGATOR, 
		GameConstants.ContextKeys.CAMERA_CONTROLLER, 
		GameConstants.ContextKeys.MOVE_CONTROLLER, 
		GameConstants.ContextKeys.GRID
	])

func execute(context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if not _payload.has(GameConstants.Payload.AXIS):
		return CommandResult.invalid_payload("Payload must have 'axis' key")
	
	var axis: Vector2 = _payload.get(GameConstants.Payload.AXIS, Vector2.ZERO)
	if axis == Vector2.ZERO:
		return CommandResult.precondition_failed("Axis is zero")

	var action: String = context.hex_navigator.get_action_from_joy_axis(
		axis, 
		context.camera_controller.get_camera_rotation(), 
		context.unit_manager.get_selected_coord(), 
		context.grid
	)
	if action.is_empty():
		return CommandResult.precondition_failed("No valid action from joy axis")

	context.move_controller.request_move(action)
	return CommandResult.success()
