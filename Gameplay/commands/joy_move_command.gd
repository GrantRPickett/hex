class_name JoyMoveCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.JOY_MOVE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.Context.UNIT_MANAGER, 
		GameConstants.Context.HEX_NAVIGATOR, 
		GameConstants.Context.CAMERA_CONTROLLER, 
		GameConstants.Context.MOVE_CONTROLLER, 
		GameConstants.Context.GRID
	])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if payload == null or not payload is Dictionary:
		return CommandResult.invalid_payload("Payload must be a Dictionary")

	if not payload.has(GameConstants.Payload.AXIS):
		return CommandResult.invalid_payload("Payload must have 'axis' key")

	var axis: Vector2 = payload.get(GameConstants.Payload.AXIS, Vector2.ZERO)
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
