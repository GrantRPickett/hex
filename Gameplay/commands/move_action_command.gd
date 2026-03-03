
class_name MoveActionCommand
extends GameCommand

static func get_command_name() -> String:
	return "move_action"

static func get_command_description() -> String:
	return "Request movement in a cardinal direction"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "hex_navigator", "camera_controller", "move_controller", "grid"])

func execute(context: GameCommandContext, action = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if action == null or not action is String:
		return CommandResult.invalid_payload("Action must be a non-null String")

	var from_coord = context.unit_manager.get_selected_coord()
	var mapped_action = context.hex_navigator.map_action_by_camera(action, from_coord, context.camera_controller.get_rotation(), context.grid)
# Keyboard move: perform immediate directional step for snappy control
	# (Mouse pathing uses confirm/cancel via primary/confirm commands.)
	context.move_controller.request_move(mapped_action)
	return CommandResult.success()