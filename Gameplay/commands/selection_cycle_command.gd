class_name SelectionCycleCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.SELECTION_CYCLE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER])

static func create_payload(direction: int) -> Dictionary:
	return {
		"direction": direction
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var direction: int = int(payload.get("direction", 1))

	var unit_manager := context.unit_manager
	var count := unit_manager.get_unit_count()
	if count <= 1:
		return CommandResult.precondition_failed("Only 1 or fewer units")

	var previous_index := unit_manager.get_selected_index()
	unit_manager.cycle_selection(direction)
	if unit_manager.get_selected_index() == previous_index:
		return CommandResult.precondition_failed("No valid unit to select")

	return CommandResult.success()
