class_name SelectionCycleCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if payload == null or not payload is int:
		return CommandResult.invalid_payload("Direction must be an int")

	var unit_manager = context.unit_manager
	var count = unit_manager.get_unit_count()

	if count <= 1:
		return CommandResult.precondition_failed("Only 1 or fewer units")

	var direction: int = payload
	var turn_controller = context.turn_controller

	if not turn_controller.is_enabled():
		unit_manager.cycle_selection(direction)
		return CommandResult.success()

	var start = unit_manager.get_selected_index()
	var current = start

	for _i in range(count):
		current = int((current + direction) % count)
		if current < 0:
			current = count - 1
		if not turn_controller.can_act_on_index(current):
			continue
		if unit_manager.is_player_controlled(current):
			unit_manager.select_index(current)
			return CommandResult.success()

	return CommandResult.precondition_failed("No valid unit to select")
