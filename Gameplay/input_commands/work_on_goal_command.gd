class_name WorkOnGoalCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "goal_controller", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["worker_index", "goal_index"])
	)
	if payload_result.is_failure():
		return payload_result

	var worker_idx: int = payload.get("worker_index", -1)
	var goal_idx: int = payload.get("goal_index", -1)

	if worker_idx < 0 or goal_idx < 0:
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

	# Get goal
	var goal = context.goal_controller.get_goal(goal_idx)
	if goal == null:
		return CommandResult.invalid_payload("Goal not found at index %d" % goal_idx)

	# Check unit is at or near goal location
	# worker_coord != goal.coord is too strict if range > 0
	if not goal.can_be_worked_on_by(worker):
		print_debug("WorkOnGoalCommand: Unit at ", worker.coord, " cannot work on goal at ", goal.coord)
		return CommandResult.precondition_failed("Unit must be at or near goal location to work on it")

	print_debug("WorkOnGoalCommand: Executing work on goal ", goal_idx, " for worker ", worker_idx)


	# Execute work on goal
	worker.work_on_goal(goal)
	return CommandResult.success()
