class_name ExploreCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.EXPLORE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit: Unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var faction = unit.get_effective_faction() if unit else GameConstants.INVALID_INDEX
	var target_info := _resolve_task_and_location(context, payload, GameConstants.TaskEvents.EXPLORE, faction)
	var task: Task = target_info.task
	var location: Location = target_info.location

	if task == null:
		return CommandResult.invalid_payload("Task required for explore")
	if not is_instance_valid(location):
		return CommandResult.invalid_payload("Location required for explore")

	CommandHistory.push_snapshot(context)
	if unit.interaction.interact(location):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Explore failed")

func _resolve_task_and_location(context: GameCommandContext, payload, required_event: String, faction: int = GameConstants.INVALID_INDEX) -> Dictionary:
	var task: Task = null
	var location: Location = null
	var manager: TaskManager = _get_task_manager(context)

	if payload is Task:
		task = payload
	elif payload is Location:
		location = payload
	elif payload is Dictionary:
		var raw_target = payload.get(GameConstants.Payload.TARGET)
		if raw_target is Location:
			location = raw_target

		var task_id: String = payload.get(GameConstants.Payload.TASK_ID, "")
		if task == null and not task_id.is_empty() and manager:
			task = manager.get_task_by_id(task_id)

		if task == null:
			var target_coord: Vector2i = payload.get(GameConstants.Payload.TARGET_COORD, GameConstants.INVALID_COORD)
			if target_coord != GameConstants.INVALID_COORD and manager:
				location = manager.get_location_at(target_coord)

	if task == null and manager and is_instance_valid(location):
		task = _find_task_for_location(manager, location, required_event, faction)

	if task and task.event_type != required_event:
		task = null

	if task and location == null and manager and task.target_coord != GameConstants.INVALID_COORD:
		location = manager.get_location_at(task.target_coord)

	return {"task": task, "location": location}

func _find_task_for_location(manager: TaskManager, location: Location, required_event: String, faction: int = GameConstants.INVALID_INDEX) -> Task:
	var tasks: Array[Task] = manager.get_active_tasks_for_target(location, faction)
	for task in tasks:
		if task and task.event_type == required_event:
			return task
	return null

func _get_task_manager(context: GameCommandContext) -> TaskManager:
	return context.task_manager
