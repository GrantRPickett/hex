class_name TurnController
extends Node

## Manages turn-based gameplay flow.

signal turn_changed(unit: Unit)
signal round_changed(round_number: int)
signal turn_ready(unit: Unit)
signal ai_turn_started(unit: Unit)
signal player_auto_battle_changed(enabled: bool)
signal player_auto_battle_failed(reason: String)
signal turn_queue_updated()
signal enabled_changed(enabled: bool)
signal turn_started(side: int)
signal player_defeated(reason: String)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _animation_service: AnimationRequestService
var _camera_controller: CameraController
var _grid_visuals: GridVisuals
var _turn_system: TurnSystem
var _auto_battle_service: AutoBattleService
var _queue_builder: TurnQueueBuilder
var _checkpoint_manager: CheckpointManager
var _hud: Node
var _terrain_map

var _completed_units_this_round: Array[int] = []
var _enabled: bool = true

func _init() -> void:
	_turn_system = TurnSystem.new()
	_auto_battle_service = AutoBattleService.new(self)
	player_auto_battle_changed.connect(_on_auto_battle_changed)

func reset() -> void:
	_completed_units_this_round.clear()
	_auto_battle_service.reset()

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	_ai_controller = state.ai_controller
	if _ai_controller:
		_ai_controller.set_turn_controller(self)
	_animation_service = state.animation_service
	_camera_controller = state.camera_controller
	_grid_visuals = state.grid_visuals
	_auto_battle_service.setup(_unit_manager, _ai_controller)
	_queue_builder = TurnQueueBuilder.new(_unit_manager)
	if _unit_manager and not _unit_manager.unit_removed.is_connected(_on_unit_removed):
		_unit_manager.unit_removed.connect(_on_unit_removed)

func configure_dependencies(checkpoint_manager: CheckpointManager, hud: Node, terrain_map) -> void:
	_checkpoint_manager = checkpoint_manager
	_hud = hud
	_terrain_map = terrain_map

func start_next_turn() -> void:
	if not _enabled:
		return

	if _turn_system.is_queue_empty():
		_start_new_round()
		if _turn_system.is_queue_empty():
			return

	var index = _turn_system.peek_next_index()
	var unit = _unit_manager.get_unit(index)

	# Only edge case: skip dead or exhausted units
	if not is_instance_valid(unit) or unit.is_dead or unit.get_current_willpower() <= 0:
		_turn_system.pop_next_index()
		start_next_turn.call_deferred()
		return

	_turn_system.set_current_unit_index(index)
	var side = _queue_builder.classify_unit_side(unit, index)
	_turn_system.set_current_side(side)
	
	if _unit_manager.get_selected_index() != index:
		_unit_manager.select_index(index)

	turn_changed.emit(unit)
	turn_started.emit(side)
	if EventBus: EventBus.turn_changed.emit(_turn_system.get_round(), side)

	if side == GameConstants.Side.PLAYER:
		turn_ready.emit(unit)
		_auto_battle_service.maybe_run_turn(unit)
	else:
		ai_turn_started.emit(unit)
		_process_ai_turn(unit)

func complete_turn() -> void:
	var index = _turn_system.get_current_unit_index()
	if index == GameConstants.INVALID_INDEX:
		return
	
	if not _completed_units_this_round.has(index):
		_completed_units_this_round.append(index)
		
	_turn_system.pop_next_index()
	_turn_system.set_current_unit_index(GameConstants.INVALID_INDEX)
	turn_queue_updated.emit()
	start_next_turn.call_deferred()

func _process_ai_turn(unit: Unit) -> void:
	if get_tree():
		await get_tree().create_timer(0.05).timeout
	
	if is_instance_valid(unit) and unit.get_current_willpower() > 0:
		await _ai_controller.execute_turn(unit)
	complete_turn()

func _start_new_round() -> void:
	_turn_system.increment_round()
	_completed_units_this_round.clear()
	for i in range(_unit_manager.get_unit_count()):
		var unit = _unit_manager.get_unit(i)
		if is_instance_valid(unit):
			unit.refresh_for_new_round()
	
	rebuild_turn_roster()
	round_changed.emit(_turn_system.get_round())

func rebuild_turn_roster(preserve_state: bool = false) -> void:
	var units_by_side = _queue_builder.get_active_units_by_side()
	
	if preserve_state:
		_preserve_queue_state(units_by_side)
	else:
		var start_side = _queue_builder.determine_start_side(
			units_by_side, 
			_turn_system.get_round(), 
			_turn_system.get_turns_taken_map(), 
			_turn_system.get_next_starting_side()
		)
		var result = _queue_builder.build_structured_queue(units_by_side, start_side)
		_turn_system.assign_queues(result.factions, result.units)
		_turn_system.set_next_starting_side(_queue_builder.find_next_active_side(start_side, units_by_side))
	
	turn_queue_updated.emit()
	_check_for_game_over()

func _preserve_queue_state(units_by_side: Dictionary) -> void:
	# 1. Start with current valid subqueues (handled by TurnSystem internally)
	# But for a true "roster rebuild", we want to add any NEW units to the end.
	
	# Keep existing valid units and their rotation
	# Any unit in _completed_units_this_round is skipped
	
	var current_side = _turn_system.get_current_side()
	var new_result = _queue_builder.build_structured_queue(units_by_side, current_side)
	
	# To preserve state, we take the new full queue but skip anyone who has already acted
	var final_factions: Array[int] = []
	var final_units: Dictionary = {0:[], 1:[], 2:[]}
	
	for side in new_result.units:
		for idx in new_result.units[side]:
			if not _completed_units_this_round.has(idx):
				final_units[side].append(idx)
	
	# Rebuild faction rotation based on remaining units
	# This is a bit complex to 'preserve' perfectly, so we'll just use the new rotation
	# but filtered for remaining units.
	for side in new_result.factions:
		# If this 'slot' corresponds to a unit that hasn't acted yet
		var side_units = final_units[side]
		var already_in_final = 0
		for f_side in final_factions:
			if f_side == side: already_in_final += 1
		
		if already_in_final < side_units.size():
			final_factions.append(side)
			
	_turn_system.assign_queues(final_factions, final_units)

func _on_unit_removed(_unit: Unit, index: int) -> void:
	if index == GameConstants.INVALID_INDEX:
		return

	# Update completed units list with index shifting
	var new_completed: Array[int] = []
	for c_idx in _completed_units_this_round:
		if c_idx == index: continue
		elif c_idx > index: new_completed.append(c_idx - 1)
		else: new_completed.append(c_idx)
	_completed_units_this_round = new_completed

	# Delegate removal and shifting to TurnSystem
	_turn_system.remove_unit(index)

	var current = _turn_system.get_current_unit_index()
	if current == index:
		_turn_system.set_current_unit_index(GameConstants.INVALID_INDEX)
		start_next_turn.call_deferred()
	elif current > index:
		_turn_system.set_current_unit_index(current - 1)

	turn_queue_updated.emit()
	_check_for_game_over()

func _check_for_game_over() -> void:
	var counts = get_faction_turn_counts()
	if counts[GameConstants.Side.PLAYER]["total"] == 0:
		player_defeated.emit(tr("msg.defeat_all_units"))

func get_faction_turn_counts(unit_manager: UnitManager = null) -> Dictionary:
	var counts = {
		GameConstants.Side.PLAYER: {"remaining": 0, "total": 0},
		GameConstants.Side.ENEMY: {"remaining": 0, "total": 0},
		GameConstants.Side.NEUTRAL: {"remaining": 0, "total": 0}
	}
	var um = unit_manager if unit_manager else _unit_manager
	if not um: return counts

	for i in range(um.get_unit_count()):
		var unit = um.get_unit(i)
		if is_instance_valid(unit) and not unit.is_dead:
			var side = _queue_builder.classify_unit_side(unit, i)
			counts[side]["total"] += 1

	for idx in _turn_system.get_turn_queue():
		var unit = um.get_unit(idx)
		if is_instance_valid(unit):
			var side = _queue_builder.classify_unit_side(unit, idx)
			counts[side]["remaining"] += 1
	return counts

func on_turn_changed(unit: Unit) -> void:
	if not _checkpoint_manager or not _unit_manager:
		return
		
	var idx = _unit_manager.get_unit_index(unit)
	if idx != GameConstants.INVALID_INDEX and _unit_manager.is_player_controlled(idx):
		if not is_player_auto_battle_enabled():
			_checkpoint_manager.on_checkpoint_requested()

func _on_auto_battle_changed(enabled: bool) -> void:
	if _animation_service:
		_animation_service.set_batch_deferred(enabled)
	if _camera_controller:
		_camera_controller.set_batch_mode(enabled)
	if is_instance_valid(_grid_visuals):
		_grid_visuals.set_suppress_updates(enabled)

# Compatibility methods
func can_act_on_index(index: int) -> bool:
	if not _enabled or index < 0: return false
	var unit = _unit_manager.get_unit(index)
	if not is_instance_valid(unit) or unit.is_dead or unit.get_current_willpower() <= 0: return false
	
	# If player controlled, check turn queue. If AI, just check if it's their side's turn.
	if _unit_manager.is_player_controlled(index):
		return _turn_system.get_current_side() == GameConstants.Side.PLAYER and _turn_system.get_turn_queue().has(index)
	
	# Allow AI if it's the current AI turn side
	var current_side = _turn_system.get_current_side()
	return current_side != GameConstants.Side.PLAYER and _queue_builder.classify_unit_side(unit, index) == current_side

func is_player_auto_control_locked() -> bool: return _auto_battle_service.is_in_progress()
func lock_active_player_unit(index: int) -> void:
	if _turn_system.get_current_side() != GameConstants.Side.PLAYER: return
	var pos = _turn_system.get_turn_queue().find(index)
	if pos != -1:
		_turn_system.move_index_to_front(index, pos)
		_turn_system.set_current_unit_index(index)

func complete_player_activation(index: int) -> void:
	var unit = _unit_manager.get_unit(index)
	if unit and not unit.movement.has_move_available() and not unit.res.has_action_available():
		complete_turn()

# Getters/Setters
func is_player_auto_battle_enabled() -> bool: return _auto_battle_service.is_enabled()
func set_player_auto_battle_enabled(enabled: bool) -> void: _auto_battle_service.set_enabled(enabled)
func force_disable_auto_battle(reason: String = "") -> void: _auto_battle_service.force_disable(reason)
func get_current_unit_index() -> int: return _turn_system.get_current_unit_index()
func get_current_side() -> int: return _turn_system.get_current_side()
func get_round() -> int: return _turn_system.get_round()
func get_turn_queue() -> Array[int]: return _turn_system.get_turn_queue()
func get_turn_system() -> TurnSystem: return _turn_system
func should_skip_animation_delays() -> bool: return _animation_service != null and _animation_service.should_skip_delays()
func set_current_unit_index(index: int) -> void: _turn_system.set_current_unit_index(index)
func move_index_to_front(target_index: int, list_position: int) -> void: _turn_system.move_index_to_front(target_index, list_position)
func set_enabled(enabled: bool) -> void: _enabled = enabled
func is_enabled() -> bool: return _enabled
func is_turn_active() -> bool: return _turn_system.get_current_unit_index() != GameConstants.INVALID_INDEX
func set_player_turn_locked(_locked: bool) -> void: pass # Simplified out
func is_player_turn_locked() -> bool: return false # Simplified out

func create_memento() -> Dictionary:
	return _turn_system.create_memento()

func restore_from_memento(memento: Dictionary) -> void:
	_turn_system.restore_from_memento(memento)
	var unit = _unit_manager.get_unit(_turn_system.get_current_unit_index()) if _unit_manager else null
	turn_changed.emit(unit)
