class_name MoveActionCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.MOVE_ACTION

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER, 
		GameConstants.ContextKeys.HEX_NAVIGATOR, 
		GameConstants.ContextKeys.CAMERA_CONTROLLER, 
		GameConstants.ContextKeys.MOVE_CONTROLLER, 
		GameConstants.ContextKeys.GRID
	])

func execute(context: GameCommandContext, action = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if action == null or not action is String:
		return CommandResult.invalid_payload("Action must be a non-null String")

	var from_coord: Vector2i = context.unit_manager.get_selected_coord()
	var mapped_action = context.hex_navigator.map_action_by_camera(
		action, 
		from_coord, 
		context.camera_controller.get_camera_rotation(), 
		context.grid
	)
	# Keyboard move: perform immediate directional step for snappy control
	# (Mouse pathing uses confirm/cancel via primary/confirm commands.)
	context.move_controller.request_move(mapped_action)
	return CommandResult.success()
