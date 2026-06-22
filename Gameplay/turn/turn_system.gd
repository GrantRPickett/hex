class_name TurnSystem
extends RefCounted

# Structured turn state for better readability and management
var _faction_queue: Array[int] = [] # The order of factions to act: [P, E, N, P, E]
var _unit_queues: Dictionary = {
	GameConstants.Side.PLAYER: [],
	GameConstants.Side.ENEMY: [],
	GameConstants.Side.NEUTRAL: []
}

var _current_unit_index: int = GameConstants.INVALID_INDEX
var _current_turn_side: int = GameConstants.Side.PLAYER
var _round: int = 1
var _next_starting_side: int = GameConstants.Side.PLAYER

var _turns_taken_this_round: Dictionary = {
	GameConstants.Side.PLAYER: 0,
	GameConstants.Side.ENEMY: 0,
	GameConstants.Side.NEUTRAL: 0
}

func reset() -> void:
	_faction_queue.clear()
	_unit_queues = {
		GameConstants.Side.PLAYER: [],
		GameConstants.Side.ENEMY: [],
		GameConstants.Side.NEUTRAL: []
	}
	_current_unit_index = GameConstants.INVALID_INDEX
	_current_turn_side = GameConstants.Side.PLAYER
	_round = 1
	_next_starting_side = GameConstants.Side.PLAYER
	reset_turns_taken_this_round()

func assign_queues(faction_queue: Array[int], unit_queues: Dictionary) -> void:
	_faction_queue = faction_queue.duplicate()
	_unit_queues = unit_queues.duplicate()
	# Ensure all sides are present
	for side in [GameConstants.Side.PLAYER, GameConstants.Side.ENEMY, GameConstants.Side.NEUTRAL]:
		if not _unit_queues.has(side):
			_unit_queues[side] = []

func get_turn_queue() -> Array[int]:
	# Reconstruct flat view for HUD and legacy compatibility
	var flat: Array[int] = []
	var consumed = {
		GameConstants.Side.PLAYER: 0,
		GameConstants.Side.ENEMY: 0,
		GameConstants.Side.NEUTRAL: 0
	}
	for side in _faction_queue:
		var q = _unit_queues.get(side, [])
		var idx = consumed.get(side, 0)
		if idx < q.size():
			flat.append(q[idx])
			consumed[side] = idx + 1
	return flat

func set_turn_queue(queue: Array[int]) -> void:
	# Note: This flat setter is discouraged; use assign_queues instead.
	# We can't safely decompose without a classifier, so we'll just clear for now
	# or keep it as a no-op if we want to force structured updates.
	# For safety during refactor, we'll log a warning.
	if queue.is_empty():
		_faction_queue.clear()
		for side in _unit_queues: _unit_queues[side].clear()

func is_queue_empty() -> bool:
	return _faction_queue.is_empty()

func get_queue_size() -> int:
	return _faction_queue.size()

func peek_next_index() -> int:
	if _faction_queue.is_empty():
		return GameConstants.INVALID_INDEX
	var side = _faction_queue[0]
	var q = _unit_queues.get(side, [])
	return q[0] if not q.is_empty() else GameConstants.INVALID_INDEX

func pop_next_index() -> void:
	if not _faction_queue.is_empty():
		var side = _faction_queue.pop_front()
		if _unit_queues.has(side) and not _unit_queues[side].is_empty():
			_unit_queues[side].pop_front()

func move_index_to_front(target_index: int, _list_position: int) -> void:
	var side = find_unit_side(target_index)
	if side == -1: return
	
	# 1. Move unit to front of its side sub-queue
	var q: Array = _unit_queues[side]
	var u_idx = q.find(target_index)
	if u_idx != -1:
		q.remove_at(u_idx)
		q.insert(0, target_index)
	
	# 2. Move the side occurrence that corresponded to this unit to the front of faction_queue
	# If u_idx was 2, we find the 2nd occurrence of 'side' and move it to index 0.
	var count = 0
	for i in range(_faction_queue.size()):
		if _faction_queue[i] == side:
			if count == u_idx:
				_faction_queue.remove_at(i)
				_faction_queue.insert(0, side)
				break
			count += 1

func find_unit_side(index: int) -> int:
	for side in _unit_queues:
		if _unit_queues[side].has(index):
			return side
	return -1

func remove_unit(index: int) -> void:
	# 1. Find and remove the unit and its corresponding faction slot
	var found_side = -1
	for side in _unit_queues:
		var pos = _unit_queues[side].find(index)
		if pos != -1:
			found_side = side
			_unit_queues[side].remove_at(pos)
			
			# Remove the pos-th occurrence of 'side' in faction_queue
			var count = 0
			for i in range(_faction_queue.size()):
				if _faction_queue[i] == side:
					if count == pos:
						_faction_queue.remove_at(i)
						break
					count += 1
			break
	
	# 2. Shift all remaining indices > index down by 1 in all unit queues
	for side in _unit_queues:
		var q: Array = _unit_queues[side]
		for i in range(q.size()):
			if q[i] > index:
				q[i] -= 1

func get_current_unit_index() -> int:
	return _current_unit_index

func set_current_unit_index(index: int) -> void:
	_current_unit_index = index

func get_current_side() -> int:
	return _current_turn_side

func set_current_side(side: int) -> void:
	_current_turn_side = side

func get_round() -> int:
	return _round

func get_current_round() -> int:
	return _round

func set_round(value: int) -> void:
	_round = max(1, value)

func increment_round() -> void:
	_round += 1

func get_next_starting_side() -> int:
	return _next_starting_side

func set_next_starting_side(side: int) -> void:
	_next_starting_side = side

func get_turns_taken_map() -> Dictionary:
	return _turns_taken_this_round

func set_turns_taken_map(map: Dictionary) -> void:
	if map == null or map.is_empty():
		reset_turns_taken_this_round()
		return
	_turns_taken_this_round = map.duplicate()
	for side in [GameConstants.Side.PLAYER, GameConstants.Side.ENEMY, GameConstants.Side.NEUTRAL]:
		if not _turns_taken_this_round.has(side):
			_turns_taken_this_round[side] = 0

func reset_turns_taken_this_round() -> void:
	_turns_taken_this_round = {
		GameConstants.Side.PLAYER: 0,
		GameConstants.Side.ENEMY: 0,
		GameConstants.Side.NEUTRAL: 0
	}

func create_memento() -> Dictionary:
	return {
		"faction_queue": _faction_queue.duplicate(),
		"unit_queues": _unit_queues.duplicate(),
		"current_unit_index": _current_unit_index,
		"current_turn_side": _current_turn_side,
		"round": _round,
		"next_starting_side": _next_starting_side,
		"turns_taken_this_round": _turns_taken_this_round.duplicate()
	}

func restore_from_memento(memento: Dictionary) -> void:
	_faction_queue = memento.get("faction_queue", [])
	_unit_queues = memento.get("unit_queues", {0:[], 1:[], 2:[]})
	_current_unit_index = memento.get("current_unit_index", GameConstants.INVALID_INDEX)
	_current_turn_side = memento.get("current_turn_side", GameConstants.Side.NEUTRAL)
	_round = memento.get("round", 1)
	_next_starting_side = memento.get("next_starting_side", GameConstants.Side.PLAYER)
	_turns_taken_this_round = memento.get("turns_taken_this_round", {0:0, 1:0, 2:0})
