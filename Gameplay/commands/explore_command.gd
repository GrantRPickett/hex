class_name ExploreCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.EXPLORE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER, GameConstants.Context.TASK_CONTROLLER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var task_id: String = ""
	var target_node: Target = null

	if payload is Dictionary:
		task_id = payload.get(GameConstants.Payload.TASK_ID, "")
		target_node = payload.get(GameConstants.Payload.TARGET)

	if task_id.is_empty():
		return CommandResult.invalid_payload("Task ID required for exploration")

	var task = context.task_controller.get_task_by_id(task_id)
	if task == null:
		return CommandResult.failed("Task not found: %s" % task_id)

	# Snapshot state before interaction
	CommandHistory.push_snapshot(context)

	if unit.interaction.explore(task, target_node):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Explore failed")
