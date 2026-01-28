class_name AttackUnitCommand
extends GameCommand

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
		PackedStringArray(["attacker_index", "target_index"])
	)
	if payload_result.is_failure():
		return payload_result

	var attacker_idx: int = payload.get("attacker_index", -1)
	var target_idx: int = payload.get("target_index", -1)

	if attacker_idx < 0 or target_idx < 0:
		return CommandResult.invalid_payload("Invalid unit indices")

	# Get units
	var attacker = context.unit_manager.get_unit(attacker_idx)
	var target = context.unit_manager.get_unit(target_idx)

	if attacker == null or target == null:
		return CommandResult.invalid_payload("Unit not found at given indices")

	# Check preconditions
	if not context.turn_controller.can_act_on_index(attacker_idx):
		return CommandResult.precondition_failed("Unit cannot act this turn")

	if not attacker.has_action_available():
		return CommandResult.precondition_failed("Unit has no actions available")

	if attacker == target:
		return CommandResult.precondition_failed("Cannot attack self")

	if target.faction == attacker.faction:
		return CommandResult.precondition_failed("Cannot attack ally")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var adjacent_units = attacker.get_adjacent_units([target])
	if not adjacent_units.has(target):
		return CommandResult.precondition_failed("Target is not adjacent")

	# Execute attack
	var attr_idx: int = payload.get("attribute_index", 0)
	attacker.attack_unit(target, attr_idx)
	return CommandResult.success()
