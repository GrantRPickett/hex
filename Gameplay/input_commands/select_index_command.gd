
class_name SelectIndexCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload is an int index
	if payload == null or not payload is int:
		return CommandResult.invalid_payload("Index must be a non-null int")

	var index: int = payload
	if not context.turn_controller.can_act_on_index(index):
		return CommandResult.precondition_failed("Cannot act on unit at index %d" % index)

	context.unit_manager.select_index(index)
	return CommandResult.success()
