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
	#   1. A Location object directly
	#   2. payload["target"] as a Location
	#   3. payload["task_id"] → look up via task_controller → get location at task coord
	var target: Location = null
	if payload is Location:
		target = payload
	elif payload is Dictionary:
		var raw_target = payload.get(GameConstants.Payload.TARGET)
		if raw_target is Location:
			target = raw_target
		elif target == null:
			var task_id: String = payload.get(GameConstants.Payload.TASK_ID, "")
			if not task_id.is_empty() and context.task_controller:
				var task = context.task_controller.get_task_by_id(task_id)
				if task and task.target_coord != GameConstants.INVALID_COORD:
					target = context.task_controller._task_manager.get_location_at(task.target_coord)

	if not is_instance_valid(target):
		return CommandResult.invalid_payload("Payload must be a valid Location or task_id resolving to one")

	# Final task check - only allow visit if there's an active task for this location
	if context.task_controller:
		var tasks = context.task_controller._task_manager.get_active_tasks_for_target(target)
		if tasks.is_empty():
			return CommandResult.precondition_failed("No active task for this location")

	# Snapshot state before interaction

	if unit.interaction.visit_location(target):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Visit failed")
