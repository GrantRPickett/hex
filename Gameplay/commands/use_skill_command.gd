class_name UseSkillCommand
extends GameCommand

static func get_command_name() -> String:
	return "use_skill"

static func get_command_description() -> String:
	return "Use a unit skill"

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

	if skill == null:
		return CommandResult.invalid_payload("Missing skill")

	var unit_result = CommandValidator.validate_active_unit(context, unit_index)
	if unit_result.is_failure():
		return unit_result

	var unit_manager = context.unit_manager
	var unit = unit_manager.get_unit(unit_index)

	# Activate skill
	# Note: target is currently null as we are using self-targeting or global skills like weather
	var success = skill.activate(unit, null)

	if success:
		return CommandResult.success()
	else:
		return CommandResult.failed("Skill activation failed")
