class_name CombatActionCalculator
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const ActionLabelFormatter := preload("res://Gameplay/action_label_formatter.gd")

func append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int) -> void:
	var adjacent_targets := _find_adjacent_combat_targets(unit, unit_manager)
	var reachable_targets := _find_reachable_combat_targets(unit, unit_manager, reachable_coords, axis, adjacent_targets)

	_add_attack_action(actions, adjacent_targets["enemies"], reachable_targets["enemies"])
	_add_aid_action(actions, adjacent_targets["allies"], reachable_targets["allies"])

func _find_adjacent_combat_targets(unit: Unit, unit_manager: UnitManager) -> Dictionary:
	var enemies: Array = []
	var allies: Array = []

	var friendlies = unit.get_friendly_units()
	var adjacent_friendlies = unit.get_adjacent_units(friendlies)
	for ally in adjacent_friendlies:
		if ally == unit: continue
		if ally.willpower < ally.max_willpower:
			allies.append(ally)

	var hostiles = unit.get_hostile_units()
	var adjacent_hostiles = unit.get_adjacent_units(hostiles)
	for enemy in adjacent_hostiles:
		if enemy.willpower > 0:
			enemies.append(enemy)

	return {"enemies": enemies, "allies": allies}

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int, adjacent_targets: Dictionary) -> Dictionary:
	var reachable_enemies: Array = []
	var reachable_allies: Array = []
	if reachable_coords.size() <= 1:
		return {"enemies": [], "allies": []}

	var friendlies = unit.get_friendly_units()
	for other in friendlies:
		if _should_skip_target(unit, other, adjacent_targets):
			continue
		var idx = unit_manager.get_unit_index(other)
		var other_coord = unit_manager.get_coord(idx)
		if other_coord == Vector2i(-999, -999):
			continue
		if _is_target_reachable(unit, other, reachable_coords, other_coord, axis):
			reachable_allies.append(other)

	var hostiles = unit.get_hostile_units()
	for other in hostiles:
		if _should_skip_target(unit, other, adjacent_targets):
			continue
		var idx = unit_manager.get_unit_index(other)
		var other_coord = unit_manager.get_coord(idx)
		if other_coord == Vector2i(-999, -999):
			continue
		if _is_target_reachable(unit, other, reachable_coords, other_coord, axis):
			reachable_enemies.append(other)

	return {"enemies": reachable_enemies, "allies": reachable_allies}

func _should_skip_target(unit: Unit, other: Unit, adjacent_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return adjacent_targets["enemies"].has(other) or adjacent_targets["allies"].has(other)

func _is_target_reachable(unit: Unit, other: Unit, reachable_coords: Array, other_coord: Vector2i, axis: int) -> bool:
	if other.faction != unit.faction:
		return other.willpower > 0 and has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

	# Ally case
	return other.willpower < other.max_willpower and has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

func _add_attack_action(actions: Array[Dictionary], enemies: Array, reachable_enemies: Array) -> void:
	var attack_adjacent_count = enemies.size()
	var attack_reachable_count = reachable_enemies.size()
	if attack_adjacent_count > 0 or attack_reachable_count > 0:
		var attack_action: Dictionary = {
			"type": "attack",
			"label": ActionLabelFormatter.format("Attack", attack_adjacent_count, attack_reachable_count),
			"available": attack_adjacent_count > 0
		}
		if attack_adjacent_count > 0:
			attack_action["targets"] = enemies
			attack_action["target"] = enemies[0]
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
		if aid_adjacent_count > 0:
			aid_action["targets"] = allies
			aid_action["target"] = allies[0]
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
