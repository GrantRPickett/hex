class_name InteractionExecutionService
extends RefCounted

## Shared logic for executing interactions with sequencer visuals and mechanics.
## Used by both HudActionExecutor and AIController to ensure consistent behavior.

static func execute_interaction(
	initiator: Unit, 
	target: Target, 
	action: BaseAction, 
	context: GameCommandContext,
	sequencer: InteractionSequencer,
	command_executor: Callable # func(id, payload) -> CommandResult
) -> bool:
	if sequencer == null or not is_instance_valid(target) or context == null:
		var result = command_executor.call(action.command_id, action.command_payload)
		return result is CommandResult and not result.is_failure()

	var combat_params = CombatResult.from_payload(action.command_payload, context)
	if combat_params:
		# Ensure metadata is set for the sequencer to resolve correctly
		combat_params.set_meta("action_type", action.command_payload.get("type", "unknown"))
		# Sequencer is visuals-only; avoid double HUD barks/feedback when mechanics execute after.
		combat_params.set_meta("suppress_hud_feedback", true)

	# 1. Resolve visuals (async)
	await sequencer.resolve_interaction(initiator, target, combat_params)

	# 2. Resolve mechanics (suppress redundant animations)
	var anim_service = initiator._animation_service if is_instance_valid(initiator) else null
	if anim_service:
		anim_service.set_suppress_requests(true)
	
	var result = command_executor.call(action.command_id, action.command_payload)
	
	if anim_service:
		anim_service.set_suppress_requests(false)
		
	return result is CommandResult and not result.is_failure()
