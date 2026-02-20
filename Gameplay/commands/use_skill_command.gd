class_name UseSkillCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if not payload is Dictionary:
		return CommandResult.invalid_payload("Dictionary")

	var unit_index = payload.get("unit_index", -1)
	var skill = payload.get("skill")

	if unit_index == -1 or skill == null:
		return CommandResult.invalid_payload("{ unit_index: int, skill: Skill }")

	var unit_manager = context.unit_manager
	if not unit_manager:
		return CommandResult.invalid_context(["unit_manager"])

	var unit = unit_manager.get_unit(unit_index)
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("Invalid unit")

	# Check if unit has action available
	if not unit.has_action_available():
		return CommandResult.precondition_failed("No action available")

	# Activate skill
	# Note: target is currently null as we are using self-targeting or global skills like weather
	var success = skill.activate(unit, null)

	if success:
		return CommandResult.success()
	else:
		return CommandResult.failed("Skill activation failed")
