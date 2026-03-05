class_name SelectionCycleCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.SELECTION_CYCLE

static func get_command_description() -> String:
	return "Cycle through selectable units"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.Context.UNIT_MANAGER])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if payload == null or not payload is int:
		return CommandResult.invalid_payload("Direction must be an int")

	var unit_manager := context.unit_manager
	var count := unit_manager.get_unit_count()
	if count <= 1:
		return CommandResult.precondition_failed("Only 1 or fewer units")

	var previous_index := unit_manager.get_selected_index()
	unit_manager.cycle_selection(int(payload))
	if unit_manager.get_selected_index() == previous_index:
		return CommandResult.precondition_failed("No valid unit to select")

	return CommandResult.success()
