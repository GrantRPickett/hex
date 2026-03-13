class_name AttackUnitCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.ATTACK


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
		PackedStringArray([GameConstants.Payload.ATTACKER_INDEX, GameConstants.Payload.TARGET_INDEX])
	)
	if payload_result.is_failure():
		return payload_result

	var attacker_idx: int = payload.get(GameConstants.Payload.ATTACKER_INDEX, -1)
	var target_idx: int = payload.get(GameConstants.Payload.TARGET_INDEX, -1)

	var unit_result = CommandValidator.validate_active_unit(context, attacker_idx)
	if unit_result.is_failure():
		return unit_result
	var attacker = context.unit_manager.get_unit(attacker_idx)

	var target = context.unit_manager.get_unit(target_idx)
	if target == null:
		return CommandResult.invalid_payload("Target unit not found at given index")

	if attacker == target:
		return CommandResult.precondition_failed("Cannot attack self")

	if target.faction == attacker.faction:
		return CommandResult.precondition_failed("Cannot attack allies")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var adjacent_units = attacker.query.get_adjacent_units([target])
	if not adjacent_units.has(target):
		return CommandResult.precondition_failed("Target is not adjacent")

	# Execute attack
	var attr_idx: int = payload.get(GameConstants.Payload.ATTRIBUTE_INDEX, 0)
	
	if not attacker.combat.attack(target, attr_idx):
		return CommandResult.precondition_failed("Attack failed (no actions remaining)")
		
	return CommandResult.success()
