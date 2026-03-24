class_name AttackUnitCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.ATTACK


func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TURN_CONTROLLER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

static func create_payload(attacker_idx: int, target_idx: int, attr_idx: int) -> Dictionary:
	return {
		GameConstants.Payload.ATTACKER_INDEX: attacker_idx,
		GameConstants.Payload.TARGET_INDEX: target_idx,
		GameConstants.Payload.ATTRIBUTE_INDEX: attr_idx
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var attacker_idx: int = payload.get(GameConstants.Payload.ATTACKER_INDEX, -1)

	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, attacker_idx)
	if unit_result.is_failure():
		return unit_result
	var attacker: Unit = context.unit_manager.get_unit(attacker_idx)

	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, GameConstants.TaskEvents.ATTACK)
	var target: Unit = target_info.unit

	if target == null:
		return CommandResult.invalid_payload("Target unit not found for attack")

	if attacker == target:
		return CommandResult.precondition_failed("Cannot attack self")

	if target.faction == attacker.faction:
		return CommandResult.precondition_failed("Cannot attack allies")

	if target.willpower <= 0:
		return CommandResult.precondition_failed("Target is already defeated")

	var near_units: Array[Unit] = attacker.query.get_near_units([target])
	if not near_units.has(target):
		return CommandResult.precondition_failed("Target is not near")

	# Execute attack
	var attr_idx: int = payload.get(GameConstants.Payload.ATTRIBUTE_INDEX, 0)

	if not attacker.interaction.fight_unit(target, attr_idx):
		return CommandResult.precondition_failed("Attack failed (no actions remaining)")

	return CommandResult.success()
