class_name ToggleFreeCamCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["camera_controller"])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	context.camera_controller.toggle_free_cam()
	return CommandResult.success()
