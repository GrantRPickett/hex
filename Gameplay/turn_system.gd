class_name TurnSystem
extends Node

signal round_started(round_index: int, active_side: int)
signal side_changed(active_side: int)

enum Side {
	PLAYER,
	OTHER,
}

var _roster: Dictionary = {
	Side.PLAYER: [],
	Side.OTHER: [],
}
var _index_to_side: Dictionary = {}
var _spent_units: Dictionary = {}
var _active_side: int = Side.PLAYER
var _round_index: int = 1
var _initial_side: int = Side.PLAYER

func configure(player_indexes: Array[int], other_indexes: Array[int]) -> void:
	_roster[Side.PLAYER] = player_indexes.duplicate(true)
	_roster[Side.OTHER] = other_indexes.duplicate(true)
	_rebuild_index_lookup()
	_round_index = 1
	_spent_units.clear()
	_active_side = _determine_initial_side()
	round_started.emit(_round_index, _active_side)
	side_changed.emit(_active_side)

func set_initial_side(side: int) -> void:
	if side == Side.PLAYER or side == Side.OTHER:
		_initial_side = side
	else:
		_initial_side = Side.PLAYER

func can_unit_act(index: int) -> bool:
	if not _index_to_side.has(index):
		return false
	return not _spent_units.get(index, false)

func mark_unit_acted(index: int) -> void:
	if not can_unit_act(index):
		return
	_spent_units[index] = true
	var side: int = _index_to_side.get(index, -1)
	if side == -1:
		return
	var opponent := _opponent_of(side)
	if _has_unspent_units(opponent):
		_set_active_side(opponent)
	elif _has_unspent_units(side):
		_set_active_side(side)
	else:
		_start_next_round()

func get_active_side() -> int:
	return _active_side

func get_available_indexes(side: int) -> Array[int]:
	var available: Array[int] = []
	for index in _roster.get(side, []):
		if can_unit_act(index):
			available.append(index)
	return available

func _start_next_round() -> void:
	_round_index += 1
	_spent_units.clear()
	_active_side = _determine_initial_side()
	round_started.emit(_round_index, _active_side)
	side_changed.emit(_active_side)

func _set_active_side(side: int) -> void:
	if _active_side == side:
		return
	_active_side = side
	side_changed.emit(_active_side)

func _determine_initial_side() -> int:
	if _has_units(_initial_side):
		return _initial_side
	var fallback := _opponent_of(_initial_side)
	if _has_units(fallback):
		return fallback
	return _initial_side

func _has_units(side: int) -> bool:
	return not _roster.get(side, []).is_empty()

func _has_unspent_units(side: int) -> bool:
	for index in _roster.get(side, []):
		if can_unit_act(index):
			return true
	return false

func _opponent_of(side: int) -> int:
	return Side.OTHER if side == Side.PLAYER else Side.PLAYER

func _rebuild_index_lookup() -> void:
	_index_to_side.clear()
	for index in _roster[Side.PLAYER]:
		_index_to_side[index] = Side.PLAYER
	for index in _roster[Side.OTHER]:
		_index_to_side[index] = Side.OTHER

