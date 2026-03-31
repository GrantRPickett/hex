class_name PerformInteractionCommand
extends GameCommand


static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.INTERACT

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TASK_MANAGER
	])

static func create_payload(actor_idx: int, target_coord: Vector2i, type: String = "", params: Dictionary = {}) -> Dictionary:
	var payload = {
		GameConstants.Payload.UNIT_INDEX: actor_idx,
		GameConstants.Payload.TARGET_COORD: target_coord,
		"type": type
	}
	payload.merge(params, true)
	return payload

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var unit_idx: int = payload.get(GameConstants.Payload.UNIT_INDEX, GameConstants.INVALID_INDEX)
	var unit_result: CommandResult = CommandValidator.validate_active_unit(context, unit_idx)
	if unit_result.is_failure():
		return unit_result

	var unit: Unit = context.unit_manager.get_unit(unit_idx)

	var target := TargetDiscoveryService.get_target_by_id(payload.get("target_id"))

	if not is_instance_valid(target):
		return CommandResult.invalid_payload("No valid target found for interaction")

	if unit.interaction.interact(target, payload):
		return CommandResult.success()

	return CommandResult.failed("Interaction failed")
