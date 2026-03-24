class_name ConvinceUnitCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.CONVINCE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

static func create_payload(initiator_idx: int, target_idx: int) -> Dictionary:
	return {
		GameConstants.Payload.INITIATOR_INDEX: initiator_idx,
		GameConstants.Payload.TARGET_INDEX: target_idx
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var initiator_idx: int = payload.get(GameConstants.Payload.INITIATOR_INDEX, GameConstants.INVALID_INDEX)
	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, initiator_idx)
	if unit_result.is_failure():
		return unit_result
	var initiator: Unit = context.unit_manager.get_unit(initiator_idx)

	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, GameConstants.TaskEvents.CONVINCE)
	var target: Unit = target_info.unit

	if target == null:
		return CommandResult.invalid_payload("Target unit not found for convince")

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
