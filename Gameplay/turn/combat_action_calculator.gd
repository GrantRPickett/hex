class_name CombatActionCalculator
extends RefCounted

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")

func append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int) -> void:
	var adjacent_targets := _find_adjacent_combat_targets(unit, unit_manager)
	var reachable_targets := _find_reachable_combat_targets(unit, unit_manager, reachable_coords, axis, adjacent_targets)

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

	_add_attack_action(actions, unit, fight_adjacent, fight_reachable)
	_add_convince_action(actions, unit, convince_adjacent, convince_reachable)

func _find_adjacent_combat_targets(unit: Unit, _unit_manager: UnitManager) -> Dictionary:
	return _CombatDiscovery.get_adjacent_targets(unit)

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int, adjacent_targets: Dictionary) -> Dictionary:
	if reachable_coords.size() <= 1:
		return {"enemies": [], "allies": [], "neutrals": []}

	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var reachable_friendlies = _find_reachable_targets(all_targets["allies"], unit, unit_manager, reachable_coords, axis, adjacent_targets)
	var reachable_hostiles = _find_reachable_targets(all_targets["enemies"], unit, unit_manager, reachable_coords, axis, adjacent_targets)
	var reachable_neutral_units = _find_reachable_targets(all_targets["neutrals"], unit, unit_manager, reachable_coords, axis, adjacent_targets)

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

func _add_attack_action(actions: Array[Dictionary], _unit: Unit, enemies: Array, reachable_enemies: Array) -> void:
	var attack_adjacent_count = enemies.size()
	var attack_reachable_count = reachable_enemies.size()

	if attack_adjacent_count > 0 or attack_reachable_count > 0:
		var attack_action: Dictionary = {
			"type": "open_attack_menu",
			"action_id": GameConstants.ActionIds.UNIT_OPPOSED,
			"label_params": {"adjacent": attack_adjacent_count, "reachable": attack_reachable_count, "imm_label": "adjacent"},
			"available": attack_adjacent_count > 0,
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
			attack_action["hint"] = "Move adjacent to attack reachable enemies."

		actions.append(attack_action)

func _add_convince_action(actions: Array[Dictionary], _unit: Unit, convince_targets: Array, reachable_convince: Array) -> void:
	var convince_adjacent_count = convince_targets.size()
	var convince_reachable_count = reachable_convince.size()

	if convince_adjacent_count > 0 or convince_reachable_count > 0:
		var convince_action: Dictionary = {
			"type": "convince",
			"action_id": GameConstants.ActionIds.UNIT_OPPOSED,
			"label_params": {"adjacent": convince_adjacent_count, "reachable": convince_reachable_count, "is_convince": true, "imm_label": "adjacent"},
			"available": convince_adjacent_count > 0,
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
			convince_action["hint"] = "Move adjacent to convince reachable neutrals."

		actions.append(convince_action)

func has_reachable_adjacent(reachable_coords: Array, target_coord: Vector2i, axis: int, action_range: float) -> bool:
	for coord in reachable_coords:
		if coord == target_coord:
			continue
		var distance = HexNavigator.get_hex_distance(coord, target_coord, axis)
		if distance > 0 and distance <= action_range:
			return true
	return false
