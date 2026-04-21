class_name PerformInteractionCommand
extends GameCommand


static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.INTERACT

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.UNIT_MANAGER,
])

static func create_payload(actor_idx: int, target_id: Vector2i, type: String = "", params: Dictionary = {}) -> Dictionary:
	var payload = {
		GameConstants.Payload.UNIT_INDEX: actor_idx,
		GameConstants.Payload.TARGET_INDEX: target_id,
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

	var tid = payload.get("target_id")
	GameLogger.debug(GameLogger.Category.SYSTEM, "[PerformInteract] Looking for: ", tid)
	var target := TargetDiscoveryService.get_target_by_id(tid)

	if not is_instance_valid(target):
		GameLogger.warning(GameLogger.Category.SYSTEM, "[PerformInteract] Target not found")
		return CommandResult.invalid_payload("No valid target found for interaction")

	GameLogger.debug(GameLogger.Category.SYSTEM, "[PerformInteract] Found target: ", target)

	var combat_params = CombatResult.from_payload(payload, context)
	if not combat_params:
		return CommandResult.failed("Failed to resolve combat parameters")

	if unit.interaction.interact(target, combat_params):
		return CommandResult.success()

	return CommandResult.failed("Interaction failed")
