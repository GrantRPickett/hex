class_name AidAllyCommand
extends GameCommand

static func get_command_name() -> String:
	return "aid_ally"

static func get_command_description() -> String:
	return "Encouragement through a shared affinity. Restores willpower based on highest shared attribute."

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["helper_index", "target_index"])
	)
	if payload_result.is_failure():
		return payload_result

	var helper_idx: int = payload.get("helper_index", -1)
	var target_idx: int = payload.get("target_index", -1)

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
		return CommandResult.precondition_failed("Cannot aid defeated unit")

	if target.is_at_full_willpower():
		return CommandResult.precondition_failed("Target is already at full willpower")

	var adjacent_units = helper.query.get_adjacent_units([target])
	if not adjacent_units.has(target):
		return CommandResult.precondition_failed("Target is not adjacent")

	# Execute aid
	helper.combat.aid_ally(target)
	return CommandResult.success()
