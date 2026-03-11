class_name MoveToCoordCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.MOVE_TO_COORD

static func get_command_description() -> String:
	return "Move the selected unit to a specific coordinate"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.MOVE_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var coord = _extract_coord(payload)
	if coord == GameConstants.INVALID_COORD:
		return CommandResult.invalid_payload("{ coord: Vector2i }")

	if context.move_controller.request_move_to_coord(coord):
		return CommandResult.success()
	else:
		return CommandResult.failed("Move request was rejected or blocked")

func _extract_coord(payload) -> Vector2i:
	if payload is Vector2i:
		return payload
	if payload is Dictionary:
		if payload.has(GameConstants.Payload.COORD):
			return payload.get(GameConstants.Payload.COORD)
		if payload.has(GameConstants.Payload.TARGET_COORD):
			return payload.get(GameConstants.Payload.TARGET_COORD)
	return GameConstants.INVALID_COORD
