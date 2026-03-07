class_name TurnSystem
extends RefCounted

enum Side {
	PLAYER,
	ENEMY,
	NEUTRAL
}

var _turn_queue: Array[int] = []
var _current_unit_index: int = GameConstants.INVALID_INDEX
var _current_turn_side: int = Side.PLAYER
var _round: int = 1
var _next_starting_side: int = Side.PLAYER

var _turns_taken_this_round: Dictionary = {
	Side.PLAYER: 0,
	Side.ENEMY: 0,
	Side.NEUTRAL: 0
}

func reset() -> void:
	_turn_queue.clear()
	_current_unit_index = GameConstants.INVALID_INDEX
	_current_turn_side = Side.PLAYER
	_round = 1
	_next_starting_side = Side.PLAYER
	_turns_taken_this_round = {
		Side.PLAYER: 0,
		Side.ENEMY: 0,
		Side.NEUTRAL: 0
	}

func get_turn_queue() -> Array[int]:
	return _turn_queue

func set_turn_queue(queue: Array[int]) -> void:
	_turn_queue = queue

func is_queue_empty() -> bool:
	return _turn_queue.is_empty()

func get_queue_size() -> int:
	return _turn_queue.size()

func peek_next_index() -> int:
	if _turn_queue.is_empty():
		return GameConstants.INVALID_INDEX
	return _turn_queue[0]

func pop_next_index() -> void:
	if not _turn_queue.is_empty():
		_turn_queue.pop_front()

func move_index_to_front(target_index: int, list_position: int) -> void:
	if list_position > 0 and list_position < _turn_queue.size():
		var front = _turn_queue[0]
		_turn_queue[list_position] = front
		_turn_queue[0] = target_index

func get_current_unit_index() -> int:
	return _current_unit_index

func set_current_unit_index(index: int) -> void:
	_current_unit_index = index

func get_current_side() -> int:
	return _current_turn_side

func set_current_side(side: int) -> void:
	_current_turn_side = side

func get_current_round() -> int:
	return _round

func get_round() -> int:
	return _round

func increment_round() -> void:
	_round += 1

func get_next_starting_side() -> int:
	return _next_starting_side

func set_next_starting_side(side: int) -> void:
	_next_starting_side = side

func get_turns_taken_this_round(side: int) -> int:
	return _turns_taken_this_round.get(side, 0)

func increment_turns_taken_this_round(side: int) -> void:
	if _turns_taken_this_round.has(side):
		_turns_taken_this_round[side] += 1

func reset_turns_taken_this_round() -> void:
	_turns_taken_this_round[Side.PLAYER] = 0
	_turns_taken_this_round[Side.ENEMY] = 0
	_turns_taken_this_round[Side.NEUTRAL] = 0

func has_index_in_queue(index: int) -> bool:
	return _turn_queue.find(index) != GameConstants.INVALID_INDEX

func create_memento() -> Dictionary:
	return {
		"turn_queue": _turn_queue.duplicate(),
		"current_unit_index": _current_unit_index,
		"current_turn_side": _current_turn_side,
		"round": _round,
		"next_starting_side": _next_starting_side,
		"turns_taken_this_round": _turns_taken_this_round.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	_turn_queue = memento.get("turn_queue", [])
	_current_unit_index = memento.get("current_unit_index", GameConstants.INVALID_INDEX)
	_current_turn_side = memento.get("current_turn_side", Side.NEUTRAL)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", Side.PLAYER)

	var turns_memento: Dictionary = memento.get("turns_taken_this_round", {})
	if turns_memento.is_empty():
		reset_turns_taken_this_round()
	else:
		_turns_taken_this_round = turns_memento.duplicate()
		if not _turns_taken_this_round.has(Side.NEUTRAL):
			_turns_taken_this_round[Side.NEUTRAL] = 0
