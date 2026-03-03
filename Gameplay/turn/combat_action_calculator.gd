class_name CombatActionCalculator
extends RefCounted

func append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int) -> void:
	var adjacent_targets := _find_adjacent_combat_targets(unit, unit_manager)
	var reachable_targets := _find_reachable_combat_targets(unit, unit_manager, reachable_coords, axis, adjacent_targets)

	_add_attack_action(actions, unit, adjacent_targets["enemies"], reachable_targets["enemies"])
	_add_aid_action(actions, adjacent_targets["allies"], reachable_targets["allies"])

func _find_adjacent_combat_targets(unit: Unit, unit_manager: UnitManager) -> Dictionary:
	var enemies: Array = []
	var allies: Array = []

	var friendlies = unit.query.get_friendly_units()
	var adjacent_friendlies = unit.query.get_adjacent_units(friendlies)
	for ally in adjacent_friendlies:
		if ally == unit: continue
		if ally.willpower < ally.max_willpower:
			allies.append(ally)

	var hostiles = unit.query.get_hostile_units()
	var adjacent_hostiles = unit.query.get_adjacent_units(hostiles)
	for enemy in adjacent_hostiles:
		if enemy.willpower > 0:
			enemies.append(enemy)

	return {"enemies": enemies, "allies": allies}

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int, adjacent_targets: Dictionary) -> Dictionary:
	if reachable_coords.size() <= 1:
		return {"enemies": [], "allies": []}

	var friendlies = unit.query.get_friendly_units()
	var reachable_friendlies = _find_reachable_targets(friendlies, unit, unit_manager, reachable_coords, axis, adjacent_targets)

	var hostiles = unit.query.get_hostile_units()
	var reachable_hostiles = _find_reachable_targets(hostiles, unit, unit_manager, reachable_coords, axis, adjacent_targets)

	var neutrals = unit.query.get_neutral_units()
	var reachable_neutral_units = _find_reachable_targets(neutrals, unit, unit_manager, reachable_coords, axis, adjacent_targets)
	return {"enemies": reachable_hostiles, "allies": reachable_friendlies, "neutrals": reachable_neutral_units}

func _find_reachable_targets(units: Array, unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int, adjacent_targets: Dictionary) -> Array:
	var list = []
	for other in units:
		if _should_skip_target(unit, other, adjacent_targets):
			continue
		var idx = unit_manager.get_unit_index(other)
		var other_coord = unit_manager.get_coord(idx)
		if other_coord == Vector2i(-999, -999):
			continue
		if _is_target_reachable(unit, other, reachable_coords, other_coord, axis):
			list.append(other)
	return list

func _should_skip_target(unit: Unit, other: Unit, adjacent_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return adjacent_targets["enemies"].has(other) or adjacent_targets["allies"].has(other)

func _is_target_reachable(unit: Unit, other: Unit, reachable_coords: Array, other_coord: Vector2i, axis: int) -> bool:
	if other.faction != unit.faction:
		return other.willpower > 0 and has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

	# Ally case
	return other.willpower < other.max_willpower and has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

func _add_attack_action(actions: Array[Dictionary], unit: Unit, enemies: Array, reachable_enemies: Array) -> void:
	var attack_adjacent_count = enemies.size()
	var attack_reachable_count = reachable_enemies.size()

	if attack_adjacent_count > 0 or attack_reachable_count > 0:
		var attack_action: Dictionary = {
			"type": "open_attack_menu",
			"label": ActionLabelFormatter.format("Attack", attack_adjacent_count, attack_reachable_count),
			"available": attack_adjacent_count > 0
		}


		var attack_targets: Array = []
		attack_targets.append_array(enemies)
		attack_targets.append_array(reachable_enemies)
		if not attack_targets.is_empty():
			attack_action["targets"] = attack_targets
			attack_action["target"] = attack_targets[0]

		if attack_reachable_count > 0:
			attack_action["reachable_targets"] = reachable_enemies
			attack_action["reachable"] = true
			attack_action["hint"] = "Move adjacent to attack reachable enemies."

		actions.append(attack_action)

func _add_aid_action(actions: Array[Dictionary], allies: Array, reachable_allies: Array) -> void:
	var aid_adjacent_count = allies.size()
	var aid_reachable_count = reachable_allies.size()
	if aid_adjacent_count > 0 or aid_reachable_count > 0:
		var aid_action: Dictionary = {
			"type": "aid",
			"label": ActionLabelFormatter.format("Aid Ally", aid_adjacent_count, aid_reachable_count),
			"available": aid_adjacent_count > 0
		}
		var aid_targets: Array = []
		aid_targets.append_array(allies)
		aid_targets.append_array(reachable_allies)
		if not aid_targets.is_empty():
			aid_action["targets"] = aid_targets
			aid_action["target"] = aid_targets[0]
		if aid_reachable_count > 0:
			aid_action["reachable_targets"] = reachable_allies
			aid_action["reachable"] = true
			aid_action["hint"] = "Move adjacent to aid reachable allies."
		actions.append(aid_action)

func has_reachable_adjacent(reachable_coords: Array, target_coord: Vector2i, axis: int, action_range: float) -> bool:
	for coord in reachable_coords:
		if coord == target_coord:
			continue
		var distance = HexNavigator.get_hex_distance(coord, target_coord, axis)
		if distance > 0 and distance <= action_range:
			return true
	return false
