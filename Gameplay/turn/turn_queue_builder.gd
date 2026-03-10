class_name TurnQueueBuilder
extends RefCounted

const SIDE_ORDER := [
	TurnSystem.Side.PLAYER,
	TurnSystem.Side.ENEMY,
	TurnSystem.Side.NEUTRAL,
]

var _unit_manager: UnitManager

func _init(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager

func build_full_queue(start_side: int) -> Array[int]:
	var units_by_side = get_active_units_by_side()
	return build_from_active_units(units_by_side, start_side)

func get_active_units_by_side() -> Dictionary:
	var results := {}
	for side in SIDE_ORDER:
		results[side] = []

	if not _unit_manager:
		return results

	var count = _unit_manager.get_unit_count()
	for i in range(count):
		var unit = _unit_manager.get_unit(i)
		if not is_instance_valid(unit) or unit.willpower <= 0:
			continue
		var side = classify_unit_side(unit, i)
		results[side].append(i)

	return results

func determine_start_side(units_by_side: Dictionary, round_number: int, turns_taken_this_round: Dictionary, next_starting_side: int) -> int:
	var active_sides: Array[int] = []
	for side in SIDE_ORDER:
		var entries: Array = units_by_side.get(side, [])
		if entries.size() > 0:
			active_sides.append(side)
	
	if active_sides.is_empty():
		return TurnSystem.Side.PLAYER
		
	if round_number == 1:
		# Explicitly prioritize PLAYER in the first round if they have active units
		if units_by_side.get(TurnSystem.Side.PLAYER, []).size() > 0:
			return TurnSystem.Side.PLAYER
		return active_sides[0]

	var min_turns := INF
	var candidate_sides: Array[int] = []
	for side in active_sides:
		var turns = turns_taken_this_round.get(side, 0)
		if turns < min_turns:
			min_turns = turns
			candidate_sides = [side]
		elif turns == min_turns:
			candidate_sides.append(side)

	if candidate_sides.size() == 1:
		return candidate_sides[0]
	if candidate_sides.has(next_starting_side):
		return next_starting_side
	return candidate_sides[0]

func build_from_active_units(units_by_side: Dictionary, start_side: int) -> Array[int]:
	var total_units := 0
	var active_sides := []
	for side in SIDE_ORDER:
		var side_units = units_by_side.get(side, [])
		total_units += side_units.size()
		if not side_units.is_empty():
			active_sides.append(side)
	
	var queue: Array[int] = []
	if total_units == 0:
		return queue

	var rotation = get_side_rotation(start_side)
	# Filter rotation to only include sides that actually have units
	var active_rotation = rotation.filter(func(s): return not units_by_side.get(s, []).is_empty())
	
	if active_rotation.is_empty():
		return queue

	var consumed := {}
	for side in active_sides:
		consumed[side] = 0
		
	while queue.size() < total_units:
		var added := false
		for side in active_rotation:
			var entries: Array = units_by_side.get(side, [])
			var index: int = consumed.get(side, 0)
			if index < entries.size():
				queue.append(entries[index])
				consumed[side] = index + 1
				added = true
		if not added:
			break
	return queue

func get_side_rotation(start_side: int) -> Array[int]:
	var rotation: Array[int] = []
	var start_index = SIDE_ORDER.find(start_side)
	if start_index == GameConstants.INVALID_INDEX:
		start_index = 0
	for i in range(SIDE_ORDER.size()):
		rotation.append(SIDE_ORDER[(start_index + i) % SIDE_ORDER.size()])
	return rotation

func find_next_active_side(current_side: int, units_by_side: Dictionary) -> int:
	var rotation = get_side_rotation(current_side)
	for i in range(1, rotation.size()):
		var side = rotation[i]
		if units_by_side.get(side, []).size() > 0:
			return side
	return current_side

func classify_unit_side(unit: Unit, index: int) -> int:
	if unit.faction == Unit.Faction.NEUTRAL:
		return TurnSystem.Side.NEUTRAL
	return TurnSystem.Side.PLAYER if _unit_manager.is_player_controlled(index) else TurnSystem.Side.ENEMY
