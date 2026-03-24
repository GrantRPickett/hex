class_name ToggleFreeCamCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TOGGLE_FREE_CAM

static func create_payload() -> Dictionary:
	return {}

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.CAMERA_CONTROLLER])

func execute(context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	context.camera_controller.toggle_free_cam()
	return CommandResult.success()
