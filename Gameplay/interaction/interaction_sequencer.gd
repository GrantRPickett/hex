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
	await _run_interaction_async(initiator, target, context)

func _run_interaction_async(initiator: Unit, target: Target, context: CombatResult) -> void:
	if not is_instance_valid(initiator) or not is_instance_valid(target) or context == null:
		return

	resolution_started.emit()

	# 1. Resolve Movement (wait for move animation)
	# Assuming context.has_path() exists or we can check unit tentative move
	if initiator.movement and initiator.movement.has_tentative_move():
		# The sequencer needs to wait for the move animation to finish
		await _animation_service.animation_completed

	# 2. Focus Camera
	if _camera_controller:
		var focus_point = (initiator.position + target.position) * 0.5
		_camera_controller.center_on(focus_point)

	# 3 & 4. Initiator Juice & Barks (Parallel)
	await _resolve_phase(initiator, target, context, true)

	# 5 & 6. Counter Juice & Barks (Parallel)
	if context.counter_damage > 0:
		await _resolve_phase(target, initiator, context, false)

	# 7. Final Narrative Resolution
	await _resolve_narrative(initiator, target)

	resolution_finished.emit()

func _resolve_phase(actor: Node2D, recipient: Node2D, context: CombatResult, is_initiator: bool) -> void:
	# Check settings proactively to avoid queuing effects that will be skipped
	var should_show_juice = _should_show_juice_effects()

	# Trigger Juice only if settings allow it
	if should_show_juice:
		if is_initiator:
			_animation_service.request_interact_clash(actor, recipient, func(): return (recipient.position - actor.position).normalized(), false)
			if _hud_controller:
				# Pass correct arguments: initiator, target, attribute_index, damage, title, action_str, quality
				_hud_controller.trigger_action_feedback(actor, recipient, context.attribute_index,
					int(context.damage), "action_feedback", context.type, context.quality)
		else:
			_animation_service.request_interact_shake(recipient, false)
			if _hud_controller:
				# Pass correct arguments: initiator, target, attribute_index, damage, title, action_str, quality
				_hud_controller.trigger_action_feedback(actor, recipient, context.attribute_index,
					int(context.counter_damage), "reaction_feedback", context.type, context.quality)

	# Only await if juice was triggered and not in batch mode
	if should_show_juice and not _animation_service.is_batch_mode_active():
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
