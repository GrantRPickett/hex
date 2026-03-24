class_name ZoomCameraCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.ZOOM_CAMERA

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.CAMERA_CONTROLLER])

static func create_payload(direction: int) -> Dictionary:
	return {
		"direction": direction
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if not payload.has("direction"):
		return CommandResult.invalid_payload("Direction required in payload")

	var direction: int = int(payload.get("direction", 0))
	context.camera_controller.zoom(direction)
	return CommandResult.success()
