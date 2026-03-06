class_name CombatActionCalculator
extends RefCounted

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")

func append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reach_state: Dictionary, axis: int) -> void:
	var reachable_coords: Array[Vector2i] = reach_state.get("coords", [])
	var reachable_lookup: Dictionary = reach_state.get("lookup", {})

	var adjacent_targets := _find_adjacent_combat_targets(unit, unit_manager)
	var reachable_results := _find_reachable_combat_targets(unit, unit_manager, reachable_coords, reachable_lookup, axis, adjacent_targets)
	var reachable_targets: Dictionary = reachable_results.targets
	var target_move_data: Dictionary = reachable_results.move_data

	var fight_adjacent = []
	var fight_reachable = []
	var convince_adjacent = []
	var convince_reachable = []

	var adjacent_split = _ConvinceDiscovery.split_targets(adjacent_targets["enemies"])
	fight_adjacent = adjacent_split["fight"]
	convince_adjacent = adjacent_split["convince"]

	var reachable_split = _ConvinceDiscovery.split_targets(reachable_targets["enemies"])
	fight_reachable = reachable_split["fight"]
	convince_reachable = reachable_split["convince"]

	_add_attack_action(actions, unit, fight_adjacent, fight_reachable, target_move_data)
	_add_convince_action(actions, unit, convince_adjacent, convince_reachable, target_move_data)

func _find_adjacent_combat_targets(unit: Unit, _unit_manager: UnitManager) -> Dictionary:
	return _CombatDiscovery.get_adjacent_targets(unit)

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, axis: int, adjacent_targets: Dictionary) -> Dictionary:
	if reachable_coords.size() <= 1:
		return {"targets": {"enemies": [], "allies": [], "neutrals": []}, "move_data": {}}

	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var move_data := {}

	var reachable_friendlies = _find_reachable_targets_with_move(all_targets["allies"], unit, unit_manager, reachable_coords, reachable_lookup, axis, adjacent_targets, move_data)
	var reachable_hostiles = _find_reachable_targets_with_move(all_targets["enemies"], unit, unit_manager, reachable_coords, reachable_lookup, axis, adjacent_targets, move_data)
	var reachable_neutral_units = _find_reachable_targets_with_move(all_targets["neutrals"], unit, unit_manager, reachable_coords, reachable_lookup, axis, adjacent_targets, move_data)

	return {
		"targets": {"enemies": reachable_hostiles, "allies": reachable_friendlies, "neutrals": reachable_neutral_units},
		"move_data": move_data
	}

func _find_reachable_targets_with_move(units: Array, unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, axis: int, adjacent_targets: Dictionary, out_move_data: Dictionary) -> Array:
	var list = []
	for other in units:
		if _should_skip_target(unit, other, adjacent_targets):
			continue
		var idx = unit_manager.get_unit_index(other)
		var other_coord = unit_manager.get_coord(idx)
		if other_coord == Vector2i(-999, -999):
			continue

		var move_info = _find_best_adjacent_coord(other_coord, reachable_coords, reachable_lookup, axis, unit.action_range)
		if move_info.coord != GameConstants.INVALID_COORD:
			list.append(other)
			out_move_data[other] = move_info
	return list

func _should_skip_target(unit: Unit, other: Unit, adjacent_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return adjacent_targets["enemies"].has(other) or adjacent_targets["allies"].has(other)

func _is_target_reachable(_unit: Unit, _other: Unit, _reachable_coords: Array, _other_coord: Vector2i, _axis: int) -> bool:
	# Deprecated by _find_reachable_targets_with_move
	return false

func _add_attack_action(actions: Array[Dictionary], _unit: Unit, enemies: Array, reachable_enemies: Array, target_move_data: Dictionary) -> void:
	var attack_adjacent_count = enemies.size()
	var attack_reachable_count = reachable_enemies.size()

	if attack_adjacent_count > 0 or attack_reachable_count > 0:
		var attack_action: Dictionary = {
			"type": "open_attack_menu",
			"action_id": GameConstants.ActionIds.UNIT_OPPOSED,
			"label_params": {"adjacent": attack_adjacent_count, "reachable": attack_reachable_count, "imm_label": "adjacent"},
			"available": attack_adjacent_count > 0 or attack_reachable_count > 0,
			"needs_attribute": true
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
			attack_action["target_move_data"] = target_move_data
			attack_action["hint"] = "Move adjacent to attack reachable enemies."

		actions.append(attack_action)

func _add_convince_action(actions: Array[Dictionary], _unit: Unit, convince_targets: Array, reachable_convince: Array, target_move_data: Dictionary) -> void:
	var convince_adjacent_count = convince_targets.size()
	var convince_reachable_count = reachable_convince.size()

	if convince_adjacent_count > 0 or convince_reachable_count > 0:
		var convince_action: Dictionary = {
			"type": "convince",
			"action_id": GameConstants.ActionIds.UNIT_OPPOSED,
			"label_params": {"adjacent": convince_adjacent_count, "reachable": convince_reachable_count, "is_convince": true, "imm_label": "adjacent"},
			"available": convince_adjacent_count > 0 or convince_reachable_count > 0,
			"needs_attribute": true
		}

		var all_targets: Array = []
		all_targets.append_array(convince_targets)
		all_targets.append_array(reachable_convince)
		if not all_targets.is_empty():
			convince_action["targets"] = all_targets
			convince_action["target"] = all_targets[0]

		if convince_reachable_count > 0:
			convince_action["reachable_targets"] = reachable_convince
			convince_action["reachable"] = true
			convince_action["target_move_data"] = target_move_data
			convince_action["hint"] = "Move adjacent to convince reachable neutrals."

		actions.append(convince_action)

func _find_best_adjacent_coord(target_coord: Vector2i, reachable_coords: Array, reachable_lookup: Dictionary, axis: int, action_range: float) -> Dictionary:
	var best_coord: Vector2i = GameConstants.INVALID_COORD
	var best_cost := INF
	for coord in reachable_coords:
		if coord == target_coord: continue
		var distance = HexNavigator.get_hex_distance(coord, target_coord, axis)
		if distance > 0 and distance <= action_range:
			var cost = INF
			var data = reachable_lookup.get(coord)
			if data is Dictionary:
				cost = data.get("cost", INF)
			elif data is int or data is float:
				cost = data

			if cost < best_cost:
				best_cost = cost
				best_coord = coord
	return {"coord": best_coord, "cost": best_cost}

func has_reachable_adjacent(reachable_coords: Array, target_coord: Vector2i, axis: int, action_range: float) -> bool:
	var result = _find_best_adjacent_coord(target_coord, reachable_coords, {}, axis, action_range)
	return result.coord != GameConstants.INVALID_COORD
