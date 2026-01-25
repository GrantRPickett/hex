class_name TurnController
extends Node

# AIController class is auto-global in Godot 4

signal turn_changed(unit: Unit)
signal round_changed(round_number: int)
signal turn_ready(unit: Unit)
signal ai_turn_started(unit: Unit)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _turn_queue: Array[int]
var _current_unit_index: int
var _round: int
var _turn_system: TurnSystem
var _enabled: bool
var _next_starting_side: int
var _consecutive_turn_counter: int

func _init() -> void:
	_turn_system = TurnSystem.new(self)
	reset()

func reset() -> void:
	_turn_queue = []
	_current_unit_index = -1
	_round = 1
	_enabled = true
	_next_starting_side = TurnSystem.Side.PLAYER
	_consecutive_turn_counter = 0


func setup(unit_manager: UnitManager, ai_controller: AIController = null) -> void:
	_unit_manager = unit_manager
	_ai_controller = ai_controller

func get_turn_system() -> TurnSystem:
	return _turn_system

func set_enabled(enabled: bool) -> void:
	_enabled = enabled

func is_enabled() -> bool:
	return _enabled

func rebuild_turn_roster() -> void:
	print_debug("TurnController: rebuilding turn roster (round=", _round, ")")
	_turn_queue.clear()

	var player_units: Array[int] = []
	var enemy_units: Array[int] = []

	var count = _unit_manager.get_unit_count()

	# Add all valid units to the turn queue
	for i in range(count):
		var unit = _unit_manager.get_unit(i)
		if is_instance_valid(unit) and unit.willpower > 0:
			if _unit_manager.is_player_controlled(i):
				player_units.append(i)
			else:
				enemy_units.append(i)

	# TODO: Sort by initiative if needed
	var start_side := _next_starting_side
	if _round == 1:
		start_side = TurnSystem.Side.PLAYER

	var primary: Array[int] = player_units if start_side == TurnSystem.Side.PLAYER else enemy_units
	var secondary: Array[int] = enemy_units if start_side == TurnSystem.Side.PLAYER else player_units

	var max_len = max(primary.size(), secondary.size())
	for i in range(max_len):
		if i < primary.size():
			_turn_queue.append(primary[i])
		if i < secondary.size():
			_turn_queue.append(secondary[i])

	var diff = primary.size() - secondary.size()
	if diff > 0:
		_consecutive_turn_counter += diff
		_next_starting_side = TurnSystem.Side.ENEMY if start_side == TurnSystem.Side.PLAYER else TurnSystem.Side.PLAYER
	elif diff < 0:
		_consecutive_turn_counter += abs(diff)
		_next_starting_side = start_side
	else:
		_next_starting_side = TurnSystem.Side.ENEMY if start_side == TurnSystem.Side.PLAYER else TurnSystem.Side.PLAYER

	print_debug("TurnController: queue built size=", _turn_queue.size(), " start_side=", start_side, " next_starting_side=", _next_starting_side, " consec=", _consecutive_turn_counter)
	if _turn_queue.is_empty():
		return

	start_next_turn()

func start_next_turn() -> void:
	if not _enabled:
		print_debug("TurnController: start_next_turn skipped (disabled)")
		return

	if _turn_queue.is_empty():
		_round += 1
		round_changed.emit(_round)
		print_debug("TurnController: queue empty -> next round=", _round)

		# Refresh all units for the new round.
		if _unit_manager:
			for i in range(_unit_manager.get_unit_count()):
				var unit = _unit_manager.get_unit(i)
				if is_instance_valid(unit):
					unit.refresh_for_new_round()

		rebuild_turn_roster()
		return

	_current_unit_index = _turn_queue.pop_front()
	var unit = _unit_manager.get_unit(_current_unit_index)

	# Skip dead or invalid units
	if not is_instance_valid(unit) or unit.willpower <= 0:
		print_debug("TurnController: skipped unit index=", _current_unit_index, " (invalid or 0 WP)")
		start_next_turn()
		return

	var is_player = _unit_manager.is_player_controlled(_current_unit_index)
	print_debug("TurnController: turn changed -> index=", _current_unit_index, " player=", is_player)
	turn_changed.emit(unit)
	# Select the unit to show who is acting
	_unit_manager.select_index(_current_unit_index)
	if is_player:
		turn_ready.emit(unit)
	else:
		ai_turn_started.emit(unit)
		_process_ai_turn(unit)

func _process_ai_turn(unit: Unit) -> void:
	if _ai_controller:
		# Small delay for visual clarity before AI acts
		await get_tree().create_timer(0.5).timeout

		if is_instance_valid(unit) and unit.willpower > 0:
			await _ai_controller.execute_turn(unit)

		# Delay after action before ending turn
		await get_tree().create_timer(0.2).timeout
		complete_turn()
	else:
		complete_turn()

func complete_player_activation(index: int) -> void:
	if index != _current_unit_index:
		return

	var unit = _unit_manager.get_unit(index)
	if unit and not unit.has_move_available() and not unit.has_action_available():
		complete_turn()

func complete_turn() -> void:
	start_next_turn()

func can_act_on_index(index: int) -> bool:
	var ok = _enabled and index == _current_unit_index
	if not ok:
		print_debug("TurnController: can_act_on_index false (enabled=", _enabled, ", index=", index, ", current=", _current_unit_index, ")")
	return ok

func get_current_unit_index() -> int:
	return _current_unit_index

func get_current_side() -> int:
	if _current_unit_index == -1 or _unit_manager == null:
		return TurnSystem.Side.NEUTRAL

	var unit : Unit = _unit_manager.get_unit(_current_unit_index)
	if not is_instance_valid(unit):
		return TurnSystem.Side.NEUTRAL

	return unit.faction as int

func get_round() -> int:
	return _round

func create_memento() -> Dictionary:
	return {
		"turn_queue": _turn_queue.duplicate(),
		"current_unit_index": _current_unit_index,
		"round": _round,
		"next_starting_side": _next_starting_side,
		"consecutive_turn_counter": _consecutive_turn_counter
	}

func restore_from_memento(memento: Dictionary) -> void:
	_turn_queue = memento.get("turn_queue", [])
	_current_unit_index = memento.get("current_unit_index", -1)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", TurnSystem.Side.PLAYER)
	_consecutive_turn_counter = memento.get("consecutive_turn_counter", 0)
	turn_changed.emit(_unit_manager.get_unit(_current_unit_index))
