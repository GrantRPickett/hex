class_name WorkOnlocationCommand
extends GameCommand

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
		PackedStringArray(["worker_index", "location_index"])
	)
	if payload_result.is_failure():
		return payload_result

	var worker_idx: int = payload.get("worker_index", -1)
	var location_idx: int = payload.get("location_index", -1)

	if worker_idx < 0 or location_idx < 0:
		return CommandResult.invalid_payload("Invalid indices")

	# Get unit
	var worker = context.unit_manager.get_unit(worker_idx)
	if worker == null:
		return CommandResult.invalid_payload("Unit not found at index %d" % worker_idx)

	# Check preconditions
	if not context.turn_controller.can_act_on_index(worker_idx):
		return CommandResult.precondition_failed("Unit cannot act this turn")

	if not worker.has_action_available():
		return CommandResult.precondition_failed("Unit has no actions available")

	# Get location
	var location = context.task_controller.get_location(location_idx)
	if location == null:
		return CommandResult.invalid_payload("location not found at index %d" % location_idx)

	# Check unit is at or near location location
	# worker_coord != location.coord is too strict if range > 0
	if not location.can_be_worked_on_by(worker):
		var worker_coord := worker.get_grid_location() if worker.has_method("get_grid_location") else Vector2i(-999, -999)
		print_debug("WorkOnlocationCommand: Unit at ", worker_coord, " cannot work on location at ", location.coord)
		return CommandResult.precondition_failed("Unit must be at or near location location to work on it")

	print_debug("WorkOnlocationCommand: Executing work on location ", location_idx, " for worker ", worker_idx)


	# Execute work on location
	worker.work_on_location(location)
	return CommandResult.success()
