class_name AidAllyCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.AID

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER, GameConstants.ContextKeys.TURN_CONTROLLER])

static func create_payload(helper_idx: int, target_idx: int, attr_idx: int) -> Dictionary:
	return {
		GameConstants.Payload.HELPER_INDEX: helper_idx,
		GameConstants.Payload.TARGET_INDEX: target_idx,
		GameConstants.Payload.ATTRIBUTE_INDEX: attr_idx
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result: CommandResult = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray([GameConstants.Payload.HELPER_INDEX, GameConstants.Payload.TARGET_INDEX])
	)
	if payload_result.is_failure():
		return payload_result

	var helper_idx: int = payload.get(GameConstants.Payload.HELPER_INDEX, GameConstants.INVALID_INDEX)
	var target_idx: int = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_INDEX)
	var attr_idx: int = payload.get(GameConstants.Payload.ATTRIBUTE_INDEX, 0)

	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, helper_idx)
	if unit_result.is_failure():
		return unit_result
	var helper: Unit = context.unit_manager.get_unit(helper_idx)

	var target: Unit = context.unit_manager.get_unit(target_idx)
	if target == null:
		return CommandResult.invalid_payload("Target unit not found at given index")

	if helper == target:
		return CommandResult.precondition_failed("Cannot aid self")

	if target.faction != helper.faction:
		return CommandResult.precondition_failed("Can only aid allies")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var near_units: Array[Unit]= helper.query.get_near_units([target])
	if not near_units.has(target):
		return CommandResult.precondition_failed("Target is not near")

	# Execute aid
	if not helper.combat.aid_ally(target, attr_idx):
		return CommandResult.precondition_failed("Aid failed (no actions remaining)")

	return CommandResult.success()
