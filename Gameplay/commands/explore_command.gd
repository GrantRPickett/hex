class_name ExploreCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.EXPLORE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

static func create_payload(unit_idx: int, task_id: String) -> Dictionary:
	return {
		GameConstants.Payload.UNIT_INDEX: unit_idx,
		GameConstants.Payload.TASK_ID: task_id
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit: Unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var faction = unit.get_effective_faction() if unit else GameConstants.INVALID_INDEX
	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, GameConstants.TaskEvents.EXPLORE, faction)
	var task: Task = target_info.task
	var target: Target = target_info.target

	if task == null:
		return CommandResult.invalid_payload("Task required for explore")
	if not is_instance_valid(target):
		return CommandResult.invalid_payload("Target required for explore")

	var attr_idx: int = payload.get(GameConstants.Payload.ATTRIBUTE_INDEX, -1)
	var attr_name: String = GameConstants.get_attribute_name(attr_idx) if attr_idx != -1 else ""
	var forecast: Dictionary = payload.get(GameConstants.Payload.FORECAST_RESULTS, {})

	CommandHistory.push_snapshot(context)
	if unit.interaction.explore(task, target, attr_name, forecast):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Explore failed")

func _get_task_manager(context: GameCommandContext) -> TaskManager:
	return context.task_manager
