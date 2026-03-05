class_name ToggleFreeCamCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.TOGGLE_FREE_CAM

static func get_command_description() -> String:
	return "Toggle free camera mode"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.CAMERA_CONTROLLER])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	context.camera_controller.toggle_free_cam()
	return CommandResult.success()
