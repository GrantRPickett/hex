class_name MoveToCoordCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.MOVE_TO_COORD

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.MOVE_CONTROLLER])

static func create_payload(unit_idx: int, coord: Vector2i) -> Dictionary:
	return {
		GameConstants.Payload.UNIT_INDEX: unit_idx,
		GameConstants.Payload.COORD: coord
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit_idx: int = payload.get(GameConstants.Payload.UNIT_INDEX, -1)
	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, unit_idx)
	if unit_result.is_failure():
		return unit_result

	var coord: Vector2i = _extract_coord(payload)
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
