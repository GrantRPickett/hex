class_name WorkOnTaskCommand
extends GameCommand

static func get_command_name() -> String:
	return "work_on_task"

static func get_command_description() -> String:
	return "Work on a location at current position"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "task_controller", "turn_controller"])

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

	if task_id.is_empty():
		return CommandResult.invalid_payload("Invalid task_id")

	var unit_result = CommandValidator.validate_active_unit(context, worker_idx)
	if unit_result.is_failure():
		return unit_result
	var worker = context.unit_manager.get_unit(worker_idx)

	var task_manager = context.task_controller

	var task_to_work_on = task_manager.get_task_by_id(task_id)
	if task_to_work_on == null:
		return CommandResult.invalid_payload("Task not found for ID: %s" % task_id)

	print_debug("WorkOnTaskCommand: Working on task ", task_to_work_on.title)

	if worker.interaction.work_on_task(task_to_work_on):
		return CommandResult.success()
	
	return CommandResult.failed("Task interaction failed")
