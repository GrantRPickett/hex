class_name VisitCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.VISIT

static func get_command_description() -> String:
	return "Unopposed interaction with a location"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	# Resolve the Location target from multiple payload forms:
	var target_info = _resolve_visit_target_info(context, payload)
	var target: Location = target_info.get("target")
	var task: Task = target_info.get("task")

	# If we have a task but no location, we can still "visit" it via the exploration system
	if task and target == null:
		if unit.interaction.explore(task):
			return CommandResult.success()
		return CommandResult.failed("Visit (abstract task) failed")

	if not is_instance_valid(target):
		return CommandResult.invalid_payload("Payload must be a valid Location or task_id resolving to one")

	# Final task check - only allow visit if there's an active task for this location
	if context.task_controller:
		var tasks = context.task_controller._task_manager.get_active_tasks_for_target(target)
		if tasks.is_empty():
			# If we have a specific task_id that matches this location but isn't "active" in the same way,
			# we might still want to allow it if it's the one passed in.
			if task == null:
				return CommandResult.precondition_failed("No active task for this location")

	# Snapshot state before interaction
	CommandHistory.push_snapshot(context)

	if unit.interaction.visit_location(target):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Visit failed")

func _resolve_visit_target_info(context: GameCommandContext, payload) -> Dictionary:
	var target: Location = null
	var task: Task = null
	var task_id: String = ""

	if payload is Location:
		target = payload
	elif payload is Dictionary:
		var raw_target = payload.get(GameConstants.Payload.TARGET)
		if raw_target is Location:
			target = raw_target
		
		task_id = payload.get(GameConstants.Payload.TASK_ID, "")
		if not task_id.is_empty() and context.task_controller:
			task = context.task_controller.get_task_by_id(task_id)
			if task and target == null and task.target_coord != GameConstants.INVALID_COORD:
				target = context.task_controller._task_manager.get_location_at(task.target_coord)
	
	return {"target": target, "task": task}
