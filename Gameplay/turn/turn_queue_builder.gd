class_name TurnQueueBuilder
extends RefCounted

const SIDE_ORDER := [
	GameConstants.Side.PLAYER,
	GameConstants.Side.ENEMY,
	GameConstants.Side.NEUTRAL,
]

var _unit_manager: UnitManager

func _init(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager

func build_full_queue(start_side: GameConstants.Side) -> Array[int]:
	var units_by_side = get_active_units_by_side()
	return build_from_active_units(units_by_side, start_side)

func get_active_units_by_side() -> Dictionary:
	var results := {}
	for side in SIDE_ORDER:
		results[side] = []

	if not _unit_manager:
		return results

	var count: int = _unit_manager.get_unit_count()
	for i in range(count):
		var unit: Unit = _unit_manager.get_unit(i)
		if not is_instance_valid(unit) or unit.get_current_willpower() <= 0:
			continue
		var side = classify_unit_side(unit, i)
		results[side].append(i)

	return results

func determine_start_side(units_by_side: Dictionary, round_number: int, turns_taken_this_round: Dictionary, next_starting_side: GameConstants.Side) -> GameConstants.Side:
	var active_sides: Array[GameConstants.Side] = []
	for side in SIDE_ORDER:
		var entries: Array = units_by_side.get(side, [])
		if entries.size() > 0:
			active_sides.append(side)

	if active_sides.is_empty():
		return GameConstants.Side.PLAYER

	if round_number == 1:
		# Explicitly prioritize PLAYER in the first round if they have active units
		if units_by_side.get(GameConstants.Side.PLAYER, []).size() > 0:
			return GameConstants.Side.PLAYER
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

func build_from_active_units(units_by_side: Dictionary, start_side: GameConstants.Side) -> Array[int]:
	var result = build_structured_queue(units_by_side, start_side)
	var flat: Array[int] = []
	var consumed = {0:0, 1:0, 2:0}
	for side in result.factions:
		flat.append(result.units[side][consumed[side]])
		consumed[side] += 1
	return flat

func build_structured_queue(units_by_side: Dictionary, start_side: GameConstants.Side) -> Dictionary:
	var total_units := 0
	var active_sides: Array[GameConstants.Side] = []
	for side: GameConstants.Side in SIDE_ORDER:
		var side_units = units_by_side.get(side, [])
		total_units += side_units.size()
		if not side_units.is_empty():
			active_sides.append(side)

	if total_units == 0:
		return {"factions": [], "units": {0:[], 1:[], 2:[]}}

	var rotation = get_side_rotation(start_side)
	var active_rotation: Array[GameConstants.Side] = rotation.filter(func(s): return not units_by_side.get(s, []).is_empty())

	var faction_queue: Array[int] = []
	var unit_queues: Dictionary = {0:[], 1:[], 2:[]}
	for side in active_sides:
		unit_queues[side] = units_by_side[side].duplicate()

	var consumed := {0:0, 1:0, 2:0}
	var added_count = 0
	while added_count < total_units:
		var added_in_cycle := false
		for side in active_rotation:
			var entries: Array = units_by_side.get(side, [])
			if consumed[side] < entries.size():
				faction_queue.append(side)
				consumed[side] += 1
				added_count += 1
				added_in_cycle = true
		if not added_in_cycle:
			break
			
	return {"factions": faction_queue, "units": unit_queues}

func get_side_rotation(start_side: GameConstants.Side) -> Array[GameConstants.Side]:
	var rotation: Array[GameConstants.Side] = []
	var start_index: int = SIDE_ORDER.find(start_side)
	if start_index == GameConstants.INVALID_INDEX:
		start_index = 0
	for i in range(SIDE_ORDER.size()):
		rotation.append(SIDE_ORDER[(start_index + i) % SIDE_ORDER.size()])
	return rotation

func find_next_active_side(current_side: GameConstants.Side, units_by_side: Dictionary) -> GameConstants.Side:
	var rotation := get_side_rotation(current_side)
	for i in range(1, rotation.size()):
		var side: GameConstants.Side = rotation[i]
		if units_by_side.get(side, []).size() > 0:
			return side
	return current_side

func classify_unit_side(unit: Unit, index: int) -> GameConstants.Side:
	if unit.faction == GameConstants.Faction.NEUTRAL:
		return GameConstants.Side.NEUTRAL
	return GameConstants.Side.PLAYER if _unit_manager.is_player_controlled(index) else GameConstants.Side.ENEMY
