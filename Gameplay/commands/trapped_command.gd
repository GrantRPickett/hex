class_name TrappedCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TRAPPED

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_CONTROLLER,
		GameConstants.ContextKeys.LOOT_MANAGER
	])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit: Unit = context.get_selected_unit()
	if not is_instance_valid(unit):
		return CommandResult.precondition_failed("No unit selected")

	var loot_target: Loot = _resolve_loot_target(context, payload)
	if loot_target == null:
		return CommandResult.invalid_payload("Target loot required for trapped action")
	if not loot_target.is_trapped:
		return CommandResult.precondition_failed("Selected loot is not trapped")

	CommandHistory.push_snapshot(context)
	if unit.interaction.interact(loot_target):
		return CommandResult.success()

	CommandHistory.pop_snapshot()
	return CommandResult.failed("Disarming trap failed")


func _resolve_loot_target(context: GameCommandContext, payload) -> Loot:
	if payload is Dictionary:
		var raw_target = payload.get(GameConstants.Payload.TARGET)
		if raw_target is Loot:
			return raw_target
		var coord: Vector2i = payload.get(GameConstants.Payload.LOOT_COORD, GameConstants.INVALID_COORD)
		if coord != GameConstants.INVALID_COORD and context.loot_manager:
			return context.loot_manager.get_loot_at(coord)
	return null
