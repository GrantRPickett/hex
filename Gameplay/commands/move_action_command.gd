class_name MoveActionCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.MOVE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER, 
		GameConstants.ContextKeys.HEX_NAVIGATOR, 
		GameConstants.ContextKeys.CAMERA_CONTROLLER, 
		GameConstants.ContextKeys.MOVE_CONTROLLER, 
		GameConstants.ContextKeys.GRID
	])

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if not payload.has(GameConstants.Payload.ACTION):
		return CommandResult.invalid_payload("Missing 'action' in payload")
	
	var action: String = payload.get(GameConstants.Payload.ACTION, "")
	if action.is_empty():
		return CommandResult.invalid_payload("Action must be a non-empty String")

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
