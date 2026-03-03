class_name InteractCommand
extends GameCommand

static func get_command_name() -> String:
	return "interact"

static func get_command_description() -> String:
	return "Interact with a target (Loot, location, Unit)"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var target = payload as Target
	if not is_instance_valid(target):
		return CommandResult.invalid_payload("Payload must be a valid Target")

	# Snapshot state before interaction
	CommandHistory.push_snapshot(context)

	if unit.interaction.interaction.interact(target):
		return CommandResult.success()

	# If interaction failed, discard the snapshot
	CommandHistory.pop_snapshot()
	return CommandResult.failed("Interaction failed")