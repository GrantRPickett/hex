class_name SelectIndexCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload is an int index
	if payload == null or not payload is int:
		return CommandResult.invalid_payload("Index must be a non-null int")

	var unit_manager := context.unit_manager
	var index: int = payload
	unit_manager.select_index(index)
	if unit_manager.get_selected_index() != index:
		return CommandResult.precondition_failed("Cannot select unit at index %d" % index)

	return CommandResult.success()