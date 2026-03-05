class_name ZoomCameraCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.ZOOM_CAMERA

static func get_command_description() -> String:
	return "Zoom camera in or out"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.CAMERA_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if payload == null or not payload is int:
		return CommandResult.invalid_payload("Direction must be an int")

	context.camera_controller.zoom(payload)
	return CommandResult.success()
