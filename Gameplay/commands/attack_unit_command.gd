class_name AttackUnitCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.ATTACK


func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER, GameConstants.Context.TURN_CONTROLLER])

func execute(context: GameCommandContext, payload: Variant = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result: CommandResult = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray([GameConstants.Payload.ATTACKER_INDEX, GameConstants.Payload.TARGET_INDEX])
	)
	if payload_result.is_failure():
		return payload_result

	var p_dict: Dictionary = payload if payload is Dictionary else {}
	var attacker_idx: int = p_dict.get(GameConstants.Payload.ATTACKER_INDEX, -1)
	var target_idx: int = p_dict.get(GameConstants.Payload.TARGET_INDEX, -1)

	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, attacker_idx)
	if unit_result.is_failure():
		return unit_result
	var attacker: Unit = context.unit_manager.get_unit(attacker_idx)

	var target: Unit = context.unit_manager.get_unit(target_idx)
	if target == null:
		return CommandResult.invalid_payload("Target unit not found at given index")

	if attacker == target:
		return CommandResult.precondition_failed("Cannot attack self")

	if target.faction == attacker.faction:
		return CommandResult.precondition_failed("Cannot attack allies")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var near_units: Array[Unit]= attacker.query.get_near_units([target])
	if not near_units.has(target):
		return CommandResult.precondition_failed("Target is not near")

	# Execute attack
	var attr_idx: int = p_dict.get(GameConstants.Payload.ATTRIBUTE_INDEX, 0)

	if not attacker.combat.attack(target, attr_idx):
		return CommandResult.precondition_failed("Attack failed (no actions remaining)")

	return CommandResult.success()
