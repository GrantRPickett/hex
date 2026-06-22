class_name ZoomCameraCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.ZOOM_CAMERA

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.CAMERA_CONTROLLER])

static func create_payload(direction: int) -> Dictionary:
	return {
		GameConstants.Payload.DIRECTION: direction
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if not payload.has(GameConstants.Payload.DIRECTION):
		return CommandResult.invalid_payload("Direction required in payload")

	var direction: int = int(payload.get(GameConstants.Payload.DIRECTION, 0))
	context.camera_controller.zoom(direction)
	return CommandResult.success()
