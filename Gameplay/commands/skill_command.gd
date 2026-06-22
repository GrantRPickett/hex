class_name SkillCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.SKILL

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([GameConstants.ContextKeys.UNIT_MANAGER])

static func create_payload(unit_idx: int, skill: Dictionary) -> Dictionary:
	return {
		GameConstants.Payload.UNIT_INDEX: unit_idx,
		GameConstants.Payload.SKILL: skill
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result


	var unit_index = payload.get(GameConstants.Payload.UNIT_INDEX, GameConstants.INVALID_INDEX)
	var skill = payload.get(GameConstants.Payload.SKILL)

	if skill == null:
		return CommandResult.invalid_payload("Missing skill")

	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, unit_index)
	if unit_result.is_failure():
		return unit_result

	var unit_manager = context.unit_manager
	var unit: Unit = unit_manager.get_unit(unit_index)

	# Activate skill
	# Note: target is currently null as we are using self-targeting or global skills like weather
	var success = skill.activate(unit, null)

	if success:
		return CommandResult.success()
	else:
		return CommandResult.failed("Skill activation failed")
