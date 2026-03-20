class_name LootCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.LOOT

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TURN_CONTROLLER,
		GameConstants.ContextKeys.LOOT_MANAGER
	])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result: CommandResult = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray([GameConstants.Payload.LOOTER_INDEX, GameConstants.Payload.LOOT_COORD])
	)
	if payload_result.is_failure():
		return payload_result

	var looter_idx: int = payload.get(GameConstants.Payload.LOOTER_INDEX, GameConstants.INVALID_INDEX)
	var loot_coord: Vector2i = payload.get(GameConstants.Payload.LOOT_COORD, GameConstants.INVALID_COORD)

	if loot_coord == GameConstants.INVALID_COORD:
		return CommandResult.invalid_payload("Invalid loot coordinate")

	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, looter_idx)
	if unit_result.is_failure():
		return unit_result

	var loot_target: Loot = _get_loot_target(context, loot_coord)
	if loot_target == null:
		return CommandResult.precondition_failed("No loot found at coordinate")

	var looter: Unit = context.unit_manager.get_unit(looter_idx)
	var loot_success = looter.interaction.interact(loot_target)
	return CommandResult.success("Looting action performed") if loot_success else CommandResult.failed("Could not loot current position")


func _get_loot_target(context: GameCommandContext, coord: Vector2i) -> Loot:
	if context.loot_manager == null:
		return null
	return context.loot_manager.get_loot_at(coord)
