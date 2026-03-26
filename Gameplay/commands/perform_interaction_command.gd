class_name PerformInteractionCommand
extends GameCommand

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

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
		GameConstants.Payload.COORD: target_coord,
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
	var faction = unit.get_effective_faction()
	
	var event_type = payload.get("type", "")
	var target_info := TaskResolutionService.resolve_task_and_target(context, payload, event_type, faction)
	var target: Target = target_info.target
	var task: Task = target_info.task
	
	if not is_instance_valid(target):
		return CommandResult.invalid_payload("No valid target found for interaction")

	# Pass the resolved task into params to ensure the interaction handler uses it
	payload["task"] = task
	if unit.interaction.interact(target, payload):
		return CommandResult.success()

	return CommandResult.failed("Interaction failed")
