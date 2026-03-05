class_name LootCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.LOOT

static func get_command_description() -> String:
	return "Pick up loot at current position"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER, GameConstants.Context.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray([GameConstants.Payload.LOOTER_INDEX, GameConstants.Payload.LOOT_COORD])
	)
	if payload_result.is_failure():
		return payload_result

	var looter_idx: int = payload.get(GameConstants.Payload.LOOTER_INDEX, GameConstants.INVALID_INDEX)
	var loot_coord: Vector2i = payload.get(GameConstants.Payload.LOOT_COORD, GameConstants.INVALID_COORD)

	if loot_coord == GameConstants.INVALID_COORD:
		return CommandResult.invalid_payload("Invalid loot coordinate")

	var unit_result = CommandValidator.validate_active_unit(context, looter_idx)
	if unit_result.is_failure():
		return unit_result

	var looter = context.unit_manager.get_unit(looter_idx)
	var loot_success = looter.interaction.loot(loot_coord)

	if loot_success:
		return CommandResult.success("Looting action performed")
	else:
		return CommandResult.failed("Could not loot current position")
