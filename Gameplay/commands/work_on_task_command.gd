class_name WorkOnTaskCommand
extends GameCommand

static func get_command_name() -> String:
	return "work_on_task"

static func get_command_description() -> String:
	return "Work on a location at current position"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "task_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["worker_index", "task_id"])
	)
	if payload_result.is_failure():
		return payload_result

	var worker_idx: int = payload.get("worker_index", -1)
	var task_id: String = payload.get("task_id", "")

	if worker_idx < 0 or task_id.is_empty():
		return CommandResult.invalid_payload("Invalid worker_index or task_id")

	# Get unit
	var worker = context.unit_manager.get_unit(worker_idx)
	if worker == null:
		return CommandResult.invalid_payload("Unit not found at index %d" % worker_idx)

	# Check preconditions
	if not context.turn_controller.can_act_on_index(worker_idx):
		return CommandResult.precondition_failed("Unit cannot act this turn")

	if not worker.res.has_action_available():
		return CommandResult.precondition_failed("Unit has no actions available")

	var task_manager = context.task_manager

	var task_to_work_on = task_manager.get_task_by_id(task_id)
	if task_to_work_on == null:
		return CommandResult.invalid_payload("Task not found for ID: %s" % task_id)

	print_debug("WorkOnTaskCommand: Working on task ", task_to_work_on.title)

	worker.interaction.interaction.work_on_task(task_to_work_on)
	worker.res.consume_action()
	return CommandResult.success()
