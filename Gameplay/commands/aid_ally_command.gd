class_name AidAllyCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.AID

static func get_command_description() -> String:
	return "Encouragement through a shared affinity. Grants a bonus to all combat stats for the next action based on the aider's highest attribute."

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
		PackedStringArray([GameConstants.Payload.HELPER_INDEX, GameConstants.Payload.TARGET_INDEX])
	)
	if payload_result.is_failure():
		return payload_result

	var helper_idx: int = payload.get(GameConstants.Payload.HELPER_INDEX, GameConstants.INVALID_INDEX)
	var target_idx: int = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_INDEX)
	var attr_idx: int = payload.get(GameConstants.Payload.ATTRIBUTE_INDEX, 0)

	var unit_result = CommandValidator.validate_active_unit(context, helper_idx)
	if unit_result.is_failure():
		return unit_result
	var helper = context.unit_manager.get_unit(helper_idx)

	var target = context.unit_manager.get_unit(target_idx)
	if target == null:
		return CommandResult.invalid_payload("Target unit not found at given index")

	if helper == target:
		return CommandResult.precondition_failed("Cannot aid self")

	if target.faction != helper.faction:
		return CommandResult.precondition_failed("Can only aid allies")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var adjacent_units = helper.query.get_adjacent_units([target])
	if not adjacent_units.has(target):
		return CommandResult.precondition_failed("Target is not adjacent")

	# Execute aid
	var pair_index = attr_idx / 2
	helper.combat.aid_ally(target, pair_index)
	return CommandResult.success()
