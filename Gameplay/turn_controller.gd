class_name TurnController
extends Node

# AIController class is auto-global in Godot 4

signal turn_changed(unit_index: int)
signal round_changed(round_number: int)

var _unit_manager: UnitManager
var _ai_controller: AIController
var _turn_system: TurnSystem

var _turn_queue: Array[int] = []
var _current_unit_index: int = -1
var _round: int = 1
var _enabled: bool = true
var _next_starting_side: int = TurnSystem.Side.PLAYER
var _consecutive_turn_counter: int = 0

func _init() -> void:
	_turn_system = TurnSystem.new(self)

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

	if _turn_queue.is_empty():
		return

	start_next_turn()

func start_next_turn() -> void:
	if not _enabled:
		return

	if _turn_queue.is_empty():
		_round += 1
		round_changed.emit(_round)
		rebuild_turn_roster()
		return

	_current_unit_index = _turn_queue.pop_front()
	var unit = _unit_manager.get_unit(_current_unit_index)

	# Skip dead or invalid units
	if not is_instance_valid(unit) or unit.willpower <= 0:
		start_next_turn()
		return

	unit.refresh_turn()

	turn_changed.emit(_current_unit_index)

	# Select the unit to show who is acting
	_unit_manager.select_index(_current_unit_index)

	if not _unit_manager.is_player_controlled(_current_unit_index):
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
	return _enabled and index == _current_unit_index

func get_current_unit_index() -> int:
	return _current_unit_index

func get_current_side() -> int:
	if _current_unit_index == -1 or _unit_manager == null:
		return TurnSystem.Side.NEUTRAL

	var unit := _unit_manager.get_unit(_current_unit_index)
	if not is_instance_valid(unit):
		return TurnSystem.Side.NEUTRAL

	return unit.faction as int

func get_round() -> int:
	return _round
