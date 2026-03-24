class_name LootCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.LOOT

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TURN_CONTROLLER,
		GameConstants.ContextKeys.LOOT_MANAGER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

static func create_payload(looter_idx: int, loot_coord: Vector2i) -> Dictionary:
	return {
		GameConstants.Payload.LOOTER_INDEX: looter_idx,
		GameConstants.Payload.LOOT_COORD: loot_coord
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var looter_idx: int = payload.get(GameConstants.Payload.LOOTER_INDEX, GameConstants.INVALID_INDEX)
	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, looter_idx)
	if unit_result.is_failure():
		return unit_result

	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, GameConstants.TaskEvents.LOOT)
	var loot_target: Loot = target_info.loot

	if loot_target == null:
		return CommandResult.invalid_payload("Target loot required for looting action")

	var looter: Unit = context.unit_manager.get_unit(looter_idx)
	var loot_success = looter.interaction.interact(loot_target)
	return CommandResult.success("Looting action performed") if loot_success else CommandResult.failed("Could not loot current position")
