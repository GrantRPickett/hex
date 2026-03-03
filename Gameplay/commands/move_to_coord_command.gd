class_name MoveToCoordCommand
extends GameCommand

static func get_command_name() -> String:
	return "move_to_coord"

static func get_command_description() -> String:
	return "Move the selected unit to a specific coordinate"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["move_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var coord = _extract_coord(payload)
	if coord == Vector2i(-999, -999):
		return CommandResult.invalid_payload("{ coord: Vector2i }")

	context.move_controller.request_move_to_coord(coord)
	return CommandResult.success()

func _extract_coord(payload) -> Vector2i:
	if payload is Vector2i:
		return payload
	if payload is Dictionary:
		if payload.has("coord"):
			return payload.get("coord")
		if payload.has("target_coord"):
			return payload.get("target_coord")
	return Vector2i(-999, -999)
