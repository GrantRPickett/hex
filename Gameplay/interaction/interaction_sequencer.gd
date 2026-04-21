class_name InteractionSequencer
extends Node

## Orchestrates the high-level cinematic resolution of actions (Move + Interact).

signal resolution_started
signal resolution_finished

var _animation_service: AnimationRequestService
var _camera_controller: CameraController
var _dialogue_service: DialogueActionService
var _hud_controller: HUDController # Need access to trigger bark logic

func _init() -> void:
	pass

func setup(state: GameState) -> void:
	_animation_service = state.animation_service
	_camera_controller = state.camera_controller
	_hud_controller = state.hud_controller
	_dialogue_service = PlayerActionManager.get_dialogue_service()

func resolve_interaction(initiator: Unit, target: Target, context: CombatResult) -> void:
	var action_type = "unknown"
	if context and context.has_meta("action_type"):
		action_type = context.get_meta("action_type")
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] resolve_interaction action_type=%s context_valid=%s" % [action_type, context != null])
	await _run_interaction_async(initiator, target, context)

func _run_interaction_async(initiator: Unit, target: Target, context: CombatResult) -> void:
	var type_str = str(context.type) if context else "null"
	var opposed_str = str(context.is_opposed) if context else "null"
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] START type=%s opposed=%s" % [type_str, opposed_str])
	if not is_instance_valid(initiator) or not is_instance_valid(target) or context == null:
		GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] ABORT - invalid inputs")
		return

	resolution_started.emit()

	# 1. Resolve Movement (wait for move animation) - use timeout to ensure we don't hang
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] Step 1: Check movement")
	if initiator.movement and initiator.movement.has_tentative_move():
		GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] Step 1: Awaiting move animation")
		await _safe_await(_animation_service.animation_completed, 2.0)

	# 2. Focus Camera
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] Step 2: Focus camera")
	if _camera_controller:
		var focus_point = (initiator.position + target.position) * 0.5
		_camera_controller.center_on(focus_point)

	# 3 & 4. Initiator Juice & Barks (Parallel)
	var dmg_str = str(context.damage) if context and "damage" in context else "?"
	var act_type = str(context.type) if context and "type" in context else "?"
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] dmg=%s type=%s" % [dmg_str, act_type])
	if is_instance_valid(initiator) and is_instance_valid(target):
		await _resolve_phase(initiator, target, context, true)

	# 5 & 6. Counter Juice & Barks (Parallel)
	var counter_damage = context.counter_damage if context and "counter_damage" in context else 0
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] Step 5-6: Counter check - counter_damage=%s" % [counter_damage])
	if counter_damage > 0 and is_instance_valid(target) and is_instance_valid(initiator):
		await _resolve_phase(target, initiator, context, false)

	# 7. Final Narrative Resolution
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] Step 7: Narrative resolution")
	if is_instance_valid(initiator) and is_instance_valid(target):
		await _resolve_narrative(initiator, target)

	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] _run_interaction_async END")
	resolution_finished.emit()

func _resolve_phase(actor: Node2D, recipient: Node2D, context: CombatResult, is_initiator: bool) -> void:
	# Check settings proactively to avoid queuing effects that will be skipped
	var should_show_juice = _should_show_juice_effects()
	var phase_name = "initiator" if is_initiator else "counter"
	var interaction_type = context.type if context else "unknown"
	GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] phase=%s type=%s juice=%s" % [phase_name, interaction_type, should_show_juice])

	# Trigger Juice only if settings allow it
	if should_show_juice:
		if is_initiator:
			# Initiator animation depends on interaction type and spacing
			var is_opposed = context.is_opposed if context else false
			var anim_type = context.type if context else ""
			var same_tile_opposed = anim_type in [GameConstants.Activity.TRAPPED, GameConstants.Activity.EXPLORE]
			
			if is_opposed:
				if same_tile_opposed:
					# Same-tile opposed interactions: use shake for effort/discovery
					GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] shake")
					_animation_service.request_interact_shake(actor, false)
				else:
					# Other opposed interactions (FIGHT/CONVINCE on different tiles): use clash
					GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] clash")
					var direction_fn = func(): return (recipient.position - actor.position).normalized()
					_animation_service.request_interact_clash(actor, recipient, direction_fn, false)
			else:
				# Non-combat interactions (Gather/Visit): use jump
				GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] jump")
				_animation_service.request_interact_jump(actor, false)
			
			if _hud_controller and context:
				_hud_controller.trigger_action_feedback(actor, recipient,
					int(context.attribute_index), int(context.damage),
					"action_feedback", context.type, context.quality)
		else:
			# Counter phase: target animates (jump) + initiator animates (shake)
			GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] counter")
			_animation_service.request_interact_jump(actor, false)
			_animation_service.request_interact_shake(recipient, false)
			if _hud_controller and context:
				_hud_controller.trigger_action_feedback(actor, recipient,
					int(context.attribute_index), int(context.counter_damage),
					"reaction_feedback", context.type, context.quality)

	# Only await if juice was triggered and not in batch mode
	if should_show_juice and not _animation_service.is_batch_mode_active():
		GameLogger.debug(GameLogger.Category.COMBAT, "[InteractionSeq] await anim")
		await _safe_await(_animation_service.animation_completed, 1.0)


func _should_show_juice_effects() -> bool:
	# Show juice effects unless reduced motion is enabled or animations are being skipped
	var reduced_motion = _animation_service.is_reduced_motion_enabled()
	var skip_delays = _animation_service.should_skip_delays()
	return not reduced_motion and not skip_delays


func _resolve_narrative(initiator: Unit, target: Target) -> void:
	if not _dialogue_service or not is_instance_valid(target):
		return

	var coord: Vector2i = target.get_grid_location()
	var trigger: DialogueTrigger = _dialogue_service.get_trigger_at(coord)

	if trigger and _dialogue_service.is_dialogue_active() == false:
		_dialogue_service.trigger_at_coord(coord, initiator)
		if _dialogue_service.is_dialogue_active():
			# Safe await: dialogue might take time, but don't hang forever
			await _safe_await(_dialogue_service.dialogue_finished, 10.0)

func _safe_await(sig: Signal, timeout: float) -> void:
	if _animation_service.should_skip_delays():
		return

	var timer = get_tree().create_timer(timeout)

	# Proper race between signal and timeout
	var completed = [false]
	var on_finished = func(_arg1 = null, _arg2 = null): completed[0] = true
	sig.connect(on_finished, CONNECT_ONE_SHOT)
	timer.timeout.connect(on_finished, CONNECT_ONE_SHOT)

	while not completed[0]:
		await get_tree().process_frame
func resolve_batch_interactions(intents: Array) -> void:
	await _run_batch_interactions_async(intents)

func _run_batch_interactions_async(intents: Array) -> void:
	for intent in intents:
		if intent.has("target") and intent.has("context"):
			# Await each interaction to complete before moving to next
			await _run_interaction_async(intent.unit, intent.target, intent.context)
