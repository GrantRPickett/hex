class_name TrappedCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TRAPPED

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_CONTROLLER,
		GameConstants.ContextKeys.LOOT_MANAGER
	])

static func create_payload(worker_idx: int, task_id: String) -> Dictionary:
	return {
		GameConstants.Payload.WORKER_INDEX: worker_idx,
		GameConstants.Payload.TASK_ID: task_id
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit: Unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, GameConstants.TaskEvents.TRAPPED)
	var loot_target: Loot = target_info.loot
	
	if loot_target == null:
		return CommandResult.invalid_payload("Target loot required for trapped action")
	if not loot_target.is_trapped:
		return CommandResult.precondition_failed("Selected loot is not trapped")

	CommandHistory.push_snapshot(context)
	if unit.interaction.interact(loot_target):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Disarming trap failed")
