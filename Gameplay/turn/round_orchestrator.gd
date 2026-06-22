class_name RoundOrchestrator
extends Node

## Orchestrates turn-based phases: Parallel Movement, then Parallel/Serial Actions.

var _animation_service: AnimationRequestService
var _sequencer: InteractionSequencer

func setup(state: GameState) -> void:
	_animation_service = state.animation_service
	_sequencer = state.interaction_sequencer

func execute_turn_batch(intents: Array) -> void:
	# Phase 1: Parallel Movement
	_animation_service.set_batch_deferred(true)
	for intent in intents:
		if intent.has("move_dest") and intent.has("unit"):
			_animation_service.request_unit_move(intent.unit, intent.move_dest)
	
	_animation_service.flush_batch()
	await _animation_service.animation_completed
	
	# Phase 2: Actions
	if GameConstants.AI.BATCH_RESOLVE_ACTIONS: # Toggleable via settings/constants
		await _sequencer.resolve_batch_interactions(intents)
	else:
		for intent in intents:
			if intent.has("target") and intent.has("context"):
				await _sequencer.resolve_interaction(intent.unit, intent.target, intent.context)
