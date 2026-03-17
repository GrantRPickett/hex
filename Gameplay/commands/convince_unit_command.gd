class_name ConvinceUnitCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.CONVINCE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER, GameConstants.Context.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result: CommandResult = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray([GameConstants.Payload.INITIATOR_INDEX, GameConstants.Payload.TARGET_INDEX])
	)
	if payload_result.is_failure():
		return payload_result

	var initiator_idx: int = payload.get(GameConstants.Payload.INITIATOR_INDEX, GameConstants.INVALID_INDEX)
	var target_idx: int = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_INDEX)
	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, initiator_idx)
	if unit_result.is_failure():
		return unit_result
	var initiator: Unit = context.unit_manager.get_unit(initiator_idx)

	var target: Unit = context.unit_manager.get_unit(target_idx)
	if target == null:
		return CommandResult.invalid_payload("Target unit not found at given index")

	if initiator == target:
		return CommandResult.precondition_failed("Cannot convince self")

	if target.faction != GameConstants.Faction.NEUTRAL:
		return CommandResult.precondition_failed("Target is not neutral")

	if not target.neutral_can_be_persuaded:
		return CommandResult.precondition_failed("Target cannot be persuaded")

	if target.loyalty_type == GameConstants.Faction.STATIC:
		return CommandResult.precondition_failed("Target is static and cannot be convinced")

	var near_units: Array = initiator.query.get_near_units([target])
	if not near_units.has(target):
		return CommandResult.precondition_failed("Target is not near")

	var initiator_faction = initiator.faction
	if initiator_faction == GameConstants.Faction.NEUTRAL:
		initiator_faction = initiator.loyalty.neutral_loyalty

	# Use the interaction handler to ensure proper signal emission for task progression
	initiator.interaction.convince_unit(target)

	return CommandResult.success()
