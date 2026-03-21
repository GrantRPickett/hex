class_name TurnController
extends Node

# TurnQueueBuilder handles the complex roster and queue generation logic
# TurnSystem holds the core turn state
# AutoBattleService handles player-side automation

signal turn_changed(unit: Unit)
signal round_changed(round_number: int)
signal turn_ready(unit: Unit)
signal ai_turn_started(unit: Unit)
signal player_auto_battle_changed(enabled: bool)
signal player_auto_battle_failed(reason: String)
signal turn_queue_updated()
signal enabled_changed(enabled: bool)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _turn_queue: Array[int]:
	get: return _turn_system.get_turn_queue() if _turn_system else []
	set(value): if _turn_system: _turn_system.set_turn_queue(value)

var _current_unit_index: int:
	get: return _turn_system.get_current_unit_index() if _turn_system else GameConstants.INVALID_INDEX
	set(value): if _turn_system: _turn_system.set_current_unit_index(value)

var _current_turn_side: int:
	get: return int(_turn_system.get_current_side()) if _turn_system else int(GameConstants.Side.NEUTRAL)
	set(value): if _turn_system: _turn_system.set_current_side(value)

var _round: int:
	get: return _turn_system.get_round() if _turn_system else 1
	set(value): if _turn_system: _turn_system.set_round(value)

var _turn_system: TurnSystem
var _enabled: bool = false

var _next_starting_side: int:
	get: return int(_turn_system.get_next_starting_side()) if _turn_system else int(GameConstants.Side.PLAYER)
	set(value): if _turn_system: _turn_system.set_next_starting_side(value)

var _turns_taken_this_round: Dictionary:
	get: return _turn_system.get_turns_taken_map() if _turn_system else {}
	set(value): if _turn_system: _turn_system.set_turns_taken_map(value)

var _auto_battle_service: AutoBattleService
var _queue_builder: TurnQueueBuilder
var _player_turn_locked := false
var _player_auto_turn_in_progress: bool:
	get: return _auto_battle_service.is_in_progress() if _auto_battle_service else false
var _completed_units_this_round: Array[int] = []
var _checkpoint_manager: CheckpointManager
var _hud: Node
var _terrain_map

func set_player_turn_locked(locked: bool) -> void:
	_player_turn_locked = locked

func is_player_turn_locked() -> bool:
	return _player_turn_locked

# Lifecycle & Setup

func _init() -> void:
	_turn_system = TurnSystem.new()
	_auto_battle_service = AutoBattleService.new(self)
	reset()

func reset() -> void:
	_player_turn_locked = false
	_enabled = true
	_auto_battle_service.reset()
	_completed_units_this_round.clear()

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	_ai_controller = state.ai_controller
	if _ai_controller:
		_ai_controller.set_turn_controller(self)
	_auto_battle_service.setup(_unit_manager, _ai_controller)
	_queue_builder = TurnQueueBuilder.new(_unit_manager)

func configure_dependencies(checkpoint_manager: CheckpointManager, hud: Node, terrain_map) -> void:
	_checkpoint_manager = checkpoint_manager
	_hud = hud
	_terrain_map = terrain_map

# Turn Management Core

func start_next_turn() -> void:
	if not _enabled:
		return

	if _turn_queue.is_empty():
		_current_turn_side = GameConstants.Side.PLAYER
		_current_unit_index = GameConstants.INVALID_INDEX
		_player_turn_locked = false
		_start_new_round()
		return

	var next_index: int = _turn_queue[0]
	_start_unit_turn(next_index)

func complete_turn() -> void:
	var side = _current_turn_side
	var completed_index = _turn_queue[0] if not _turn_queue.is_empty() else GameConstants.INVALID_INDEX
	_consume_current_turn_entry()
	_player_turn_locked = false
	_current_unit_index = GameConstants.INVALID_INDEX
	_current_turn_side = GameConstants.Side.PLAYER
	if _turns_taken_this_round.has(side):
		_turns_taken_this_round[side] += 1
	
	if completed_index != GameConstants.INVALID_INDEX:
		_completed_units_this_round.append(completed_index)

	turn_queue_updated.emit()
	start_next_turn()

func _start_unit_turn(index: int) -> void:
	if _unit_manager == null:
		_consume_current_turn_entry()
		return

	var unit: Unit = _unit_manager.get_unit(index)
	if not is_instance_valid(unit) or unit.willpower <= 0:
		_consume_current_turn_entry()
		start_next_turn()
		return

	var unit_side: int = _queue_builder.classify_unit_side(unit, index)
	_current_turn_side = unit_side
	var is_player = unit_side == GameConstants.Side.PLAYER

	if is_player and not _auto_battle_service.is_enabled():
		_current_unit_index = GameConstants.INVALID_INDEX
		_player_turn_locked = false
	else:
		_current_unit_index = index
		_player_turn_locked = is_player

	turn_changed.emit(unit)
	if EventBus: EventBus.turn_changed.emit(_round, _current_turn_side)
	_sync_unit_manager_selection(index)

	if unit.has_method("movement") or "movement" in unit:
		if unit.movement != null:
			var current_coord: Vector2i = _unit_manager.get_coord(index)
			unit.movement.set_start_of_turn_grid_coord(current_coord)

	if is_player:
		_auto_battle_service.reset()
		turn_ready.emit(unit)
		_auto_battle_service.maybe_run_turn(unit)
	else:
		ai_turn_started.emit(unit)
		_process_ai_turn(unit)

func _start_new_round() -> void:
	_round += 1
	if WeatherManager: WeatherManager.advance_weather()
	round_changed.emit(_round)
	_refresh_all_units()
	_current_turn_side = GameConstants.Side.PLAYER
	_turn_system.reset_turns_taken_this_round()
	_completed_units_this_round.clear()
	rebuild_turn_roster()

# Roster & Queue Logic

func classify_unit_side(unit: Unit, index: int) -> int:
	if _queue_builder == null: _queue_builder = TurnQueueBuilder.new(_unit_manager)
	return _queue_builder.classify_unit_side(unit, index)

func rebuild_turn_roster(preserve_state: bool = false) -> void:
	if _queue_builder == null: _queue_builder = TurnQueueBuilder.new(_unit_manager)

	var old_queue := _turn_queue.duplicate()
	_turn_queue.clear()
	var units_by_side = _queue_builder.get_active_units_by_side()

	if preserve_state:
		_preserve_queue_state(old_queue, units_by_side)
	else:
		var start_side = _queue_builder.determine_start_side(units_by_side, _round, _turns_taken_this_round, _next_starting_side)
		_current_turn_side = start_side
		_turn_queue = _queue_builder.build_from_active_units(units_by_side, start_side)
		_current_unit_index = _turn_queue[0] if not _turn_queue.is_empty() else GameConstants.INVALID_INDEX
		_next_starting_side = _queue_builder.find_next_active_side(start_side, units_by_side)

	if not preserve_state and not _turn_queue.is_empty():
		start_next_turn()
	turn_queue_updated.emit()

func _preserve_queue_state(old_queue: Array[int], units_by_side: Dictionary) -> void:
	var queue_was_empty: bool = old_queue.is_empty()
	var new_queue: Array[int] = []
	for unit_idx in old_queue:
		if _is_unit_active(unit_idx):
			new_queue.append(unit_idx)

	# Get units that are active but not in the preserved queue and haven't already moved
	var remaining_units_by_side := {}
	for side in units_by_side:
		remaining_units_by_side[side] = []
		for unit_idx in units_by_side[side]:
			if not new_queue.has(unit_idx) and not _completed_units_this_round.has(unit_idx):
				remaining_units_by_side[side].append(unit_idx)

	# Determine start side for the remaining units
	var start_side: int = _next_starting_side
	if not new_queue.is_empty():
		var last_unit_idx: int = new_queue[-1]
		var last_unit: Unit = _unit_manager.get_unit(last_unit_idx)
		if last_unit:
			var last_side: int = _queue_builder.classify_unit_side(last_unit, last_unit_idx)
			start_side = _queue_builder.find_next_active_side(last_side, units_by_side)

	var additional_queue: Array[int] = _queue_builder.build_from_active_units(remaining_units_by_side, start_side)
	new_queue.append_array(additional_queue)

	_turn_queue = new_queue
	if queue_was_empty and not _turn_queue.is_empty():
		start_next_turn()

func _consume_current_turn_entry() -> void:
	if not _turn_queue.is_empty(): _turn_queue.pop_front()

# AI & Auto-Battle Logic

func _process_ai_turn(unit: Unit) -> void:
	if not _ai_controller:
		complete_turn()
		return

	if get_tree(): await get_tree().create_timer(GameConstants.UI.AI_THINK_DELAY).timeout
	if is_instance_valid(unit) and unit.willpower > 0:
		var result = await _ai_controller.execute_turn(unit)
		if not is_instance_valid(unit):
			complete_turn()
			return
		if result and get_tree(): await get_tree().create_timer(GameConstants.UI.AI_ACTION_DELAY).timeout

	complete_turn()

# Player Actions & Constraints

func on_turn_changed(unit: Unit) -> void:
	if _checkpoint_manager and _checkpoint_manager.has_method("on_checkpoint_requested"):
		_checkpoint_manager.on_checkpoint_requested()

	if is_player_auto_battle_enabled() and _unit_manager and unit:
		var idx := _unit_manager.get_unit_index(unit)
		if idx != GameConstants.INVALID_INDEX and _unit_manager.is_player_controlled(idx):
			var actions = UnitActionManager.get_available_actions(unit, _terrain_map, _unit_manager)
			var report: Dictionary = AutoBattleDiagnostics.report_unsupported_actions(unit, actions, _hud)
			if (actions.is_empty() or not bool(report.get("has_supported", false))):
				force_disable_auto_battle("Auto battle disabled: no AI-compatible actions for %s" % unit.unit_name)

func can_act_on_index(index: int) -> bool:
	if not _enabled or _unit_manager == null or index < 0: return false
	var unit: Unit = _unit_manager.get_unit(index)
	if not is_instance_valid(unit) or unit.willpower <= 0: return false

	if _unit_manager.is_player_controlled(index):
		if _current_turn_side != GameConstants.Side.PLAYER: return false
		if _turn_queue.find(index) == GameConstants.INVALID_INDEX: return false
		if _player_turn_locked and index != _current_unit_index: return false
		return true
	return index == _current_unit_index

func lock_active_player_unit(index: int) -> void:
	if _unit_manager == null or index < 0 or _current_turn_side != GameConstants.Side.PLAYER \
		or _auto_battle_service.is_enabled() or _turn_queue.is_empty(): return

	var pos := _turn_queue.find(index)
	if pos == GameConstants.INVALID_INDEX: return
	if pos != 0:
		var front = _turn_queue[0]
		_turn_queue[pos] = front
		_turn_queue[0] = index
	_current_unit_index = index
	_player_turn_locked = true

func complete_player_activation(index: int) -> void:
	if index != _current_unit_index: return
	var unit: Unit = _unit_manager.get_unit(index)
	if unit and not unit.movement.has_move_available() and not unit.res.has_action_available():
		complete_turn()

# Utility & Getters

func _sync_unit_manager_selection(index: int) -> void:
	if _unit_manager.get_selected_index() != index:
		if _unit_manager.has_method("force_select_index"):
			_unit_manager.force_select_index(index)
		else:
			_unit_manager.select_index(index)
	else:
		_unit_manager.select_index(index)

func _is_unit_active(index: int) -> bool:
	if not _unit_manager: return false
	var unit: Unit = _unit_manager.get_unit(index)
	return is_instance_valid(unit) and unit.willpower > 0

func _refresh_all_units() -> void:
	if not _unit_manager: return
	for i in range(_unit_manager.get_unit_count()):
		var unit: Unit = _unit_manager.get_unit(i)
		if is_instance_valid(unit): unit.refresh_for_new_round()

# Delegation to specialized services

func set_enabled(enabled: bool) -> void:
	if _enabled != enabled:
		_enabled = enabled
		enabled_changed.emit(enabled)

func is_enabled() -> bool: return _enabled
func set_player_auto_battle_enabled(enabled: bool) -> void: _auto_battle_service.set_enabled(enabled)
func is_player_auto_battle_enabled() -> bool: return _auto_battle_service.is_enabled()
func is_player_auto_control_locked() -> bool: return _auto_battle_service.is_in_progress()
func force_disable_auto_battle(reason: String = "") -> void: _auto_battle_service.force_disable(reason)
func is_queue_empty() -> bool: return _turn_system.is_queue_empty()
func get_turn_queue() -> Array[int]: return _turn_system.get_turn_queue()
func get_turn_system() -> TurnSystem: return _turn_system
func get_current_unit_index() -> int:
	if _current_unit_index == GameConstants.INVALID_INDEX and not _turn_queue.is_empty():
		return _turn_queue[0]
	return _current_unit_index
func get_current_side() -> int: return _current_turn_side
func get_round() -> int: return _round

# Deprecated/Forwarded for compatibility
func move_index_to_front(target_index: int, list_position: int) -> void: _turn_system.move_index_to_front(target_index, list_position)
func set_current_unit_index(index: int) -> void: _turn_system.set_current_unit_index(index)

# Memento Pattern

func create_memento() -> Dictionary:
	return {
		"turn_queue": _turn_queue.duplicate(),
		"current_unit_index": _current_unit_index,
		"current_turn_side": _current_turn_side,
		"round": _round,
		"next_starting_side": _next_starting_side,
		"turns_taken_this_round": _turns_taken_this_round.duplicate(),
		"enabled": _enabled,
		"player_auto_battle_enabled": _auto_battle_service.is_enabled(),
		"player_turn_locked": _player_turn_locked
	}

func restore_from_memento(memento: Dictionary) -> void:
	_turn_queue = memento.get("turn_queue", [])
	_current_unit_index = memento.get("current_unit_index", GameConstants.INVALID_INDEX)
	_current_turn_side = memento.get("current_turn_side", GameConstants.Side.NEUTRAL)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", GameConstants.Side.PLAYER)

	var turns_memento: Dictionary = memento.get("turns_taken_this_round", {})
	if turns_memento.is_empty():
		_turns_taken_this_round = {
			GameConstants.Side.PLAYER: 0,
			GameConstants.Side.ENEMY: 0,
			GameConstants.Side.NEUTRAL: 0
		}
	else:
		_turns_taken_this_round = turns_memento.duplicate()
		if not _turns_taken_this_round.has(GameConstants.Side.NEUTRAL):
			_turns_taken_this_round[GameConstants.Side.NEUTRAL] = 0

	_enabled = memento.get("enabled", true)
	_auto_battle_service.set_enabled(memento.get("player_auto_battle_enabled", false))
	_player_turn_locked = memento.get("player_turn_locked", false)

	var unit: Unit = null
	if _unit_manager:
		if _current_unit_index >= 0:
			_unit_manager.select_index(_current_unit_index)
			unit = _unit_manager.get_unit(_current_unit_index)
		else:
			_unit_manager.select_index(GameConstants.INVALID_INDEX)
	turn_changed.emit(unit)
	if EventBus: EventBus.turn_changed.emit(_round, _current_turn_side)
