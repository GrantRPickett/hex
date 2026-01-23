class_name UnitActionManager
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")

## Checks if a unit is completely stuck (cannot move or act on current/adjacent spaces)
static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	if not is_instance_valid(unit):
		return true

	# Dead units are stuck
	if unit.willpower <= 0:
		return true

	if _can_move_somewhere(unit, terrain_map, unit_manager):
		return false

	if _can_act_somewhere(unit, unit_manager):
		return false

	# Unit is completely stuck
	return true

static func _can_move_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	# If unit has moves available, check if they can go somewhere
	if unit.has_move_available():
		var movement_range = unit.compute_movement_range(unit.get_grid_location(), terrain_map)
		if not movement_range.is_empty():
			# Check if any reachable space is not occupied
			for coord in movement_range.keys():
				if not unit_manager.is_occupied(coord, unit_manager.get_unit_index(unit)):
					return true  # Can move somewhere
	return false

static func _can_act_somewhere(unit: Unit, unit_manager: UnitManager) -> bool:
	# If unit has actions, check if they can do anything with current or adjacent units
	if unit.has_action_available():
		var current_pos = unit.get_grid_location()
		var all_units = unit_manager.get_units()
		var action_origin = current_pos
		if unit.has_tentative_move():
			action_origin = unit.get_tentative_grid_coord()
		# Check if can work on goal at current position
		if can_work_on_goal(unit, action_origin):
			return true
		if has_loot_at_position(unit, action_origin):
			return true
		# Check adjacent units for combat or aid
		var adjacent_units = unit.get_adjacent_units(all_units)
		for adjacent_unit in adjacent_units:
			if adjacent_unit == unit:
				continue

			# Can attack enemy
			if adjacent_unit.faction != unit.faction and adjacent_unit.willpower > 0:
				return true

			# Can aid ally
			if adjacent_unit.faction == unit.faction and adjacent_unit.willpower < adjacent_unit.max_willpower:
				return true
	return false

## Returns array of available actions for a unit
static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if not is_instance_valid(unit) or unit.willpower <= 0 or unit_manager == null:
		return actions

	var all_units: Array = unit_manager.get_units().duplicate()
	var unit_index := unit_manager.get_unit_index(unit)

	var movement_origin := _get_movement_origin(unit, unit_manager, unit_index)
	var action_origin := _get_action_origin(unit, movement_origin)
	var axis := _get_grid_axis(unit)

	var reach_state := _calculate_reachable_state(unit, terrain_map, unit_manager, unit_index, movement_origin, action_origin)
	var reachable_coords: Array[Vector2i] = reach_state.coords
	var reachable_lookup: Dictionary = reach_state.lookup
	var reachable_move_spaces: int = reach_state.move_spaces

	_append_move_action(actions, reachable_move_spaces)

	if unit.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, all_units, reachable_coords, axis)

	_append_goal_action(actions, unit, action_origin)
	_append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)
	_append_wait_action(actions)

	return actions

static func _get_movement_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	var movement_origin := unit.get_grid_location()
	if unit_manager:
		var manager_coord := unit_manager.get_coord(unit_index)
		if manager_coord != Vector2i(-999, -999):
			movement_origin = manager_coord
	return movement_origin

static func _get_action_origin(unit: Unit, movement_origin: Vector2i) -> Vector2i:
	if unit.has_tentative_move():
		return unit.get_tentative_grid_coord()
	return movement_origin

static func _get_grid_axis(unit: Unit) -> int:
	if unit.grid_map and unit.grid_map.tile_set:
		return unit.grid_map.tile_set.tile_offset_axis
	return TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _calculate_reachable_state(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, movement_origin: Vector2i, action_origin: Vector2i) -> Dictionary:
	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup := {}
	reachable_coords.append(action_origin)
	reachable_lookup[action_origin] = true
	var reachable_move_spaces := 0

	if unit.has_move_available() and terrain_map:
		var movement_range = unit.compute_movement_range(movement_origin, terrain_map)
		if not movement_range.is_empty():
			for coord in movement_range.keys():
				var coord_v2: Vector2i = coord
				if not reachable_lookup.has(coord_v2):
					reachable_coords.append(coord_v2)
					reachable_lookup[coord_v2] = true
				if not unit_manager.is_occupied(coord_v2, unit_index):
					reachable_move_spaces += 1

	return {
		"coords": reachable_coords,
		"lookup": reachable_lookup,
		"move_spaces": reachable_move_spaces
	}

static func _append_move_action(actions: Array[Dictionary], reachable_move_spaces: int) -> void:
	if reachable_move_spaces > 0:
		actions.append({
			"type": "move",
			"label": "Move (%d spaces)" % reachable_move_spaces,
			"available": true
		})

static func _find_adjacent_combat_targets(unit: Unit, all_units: Array) -> Dictionary:
	var enemies: Array = []
	var allies: Array = []
	var adjacent_units = unit.get_adjacent_units(all_units)

	for adjacent_unit in adjacent_units:
		if adjacent_unit == unit:
			continue
		if adjacent_unit.faction != unit.faction and adjacent_unit.willpower > 0:
			enemies.append(adjacent_unit)
		elif adjacent_unit.faction == unit.faction and adjacent_unit.willpower < adjacent_unit.max_willpower:
			allies.append(adjacent_unit)
	return {"enemies": enemies, "allies": allies}

static func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, all_units: Array, reachable_coords: Array[Vector2i], axis: int, adjacent_targets: Dictionary) -> Dictionary:
	var reachable_enemies: Array = []
	var reachable_allies: Array = []
	if reachable_coords.size() <= 1:
		return {"enemies": [], "allies": []}

	for i in range(all_units.size()):
		var other: Unit = all_units[i]
		if _should_skip_target(unit, other, adjacent_targets):
			continue

		var other_coord = unit_manager.get_coord(i)
		if other_coord == Vector2i(-999, -999):
			continue

		if _is_target_reachable(unit, other, reachable_coords, other_coord, axis):
			if other.faction != unit.faction:
				reachable_enemies.append(other)
			else:
				reachable_allies.append(other)

	return {"enemies": reachable_enemies, "allies": reachable_allies}

static func _should_skip_target(unit: Unit, other: Unit, adjacent_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return adjacent_targets["enemies"].has(other) or adjacent_targets["allies"].has(other)

static func _is_target_reachable(unit: Unit, other: Unit, reachable_coords: Array, other_coord: Vector2i, axis: int) -> bool:
	if other.faction != unit.faction:
		return other.willpower > 0 and _has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

	# Ally case
	return other.willpower < other.max_willpower and _has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range)

static func _append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, all_units: Array, reachable_coords: Array[Vector2i], axis: int) -> void:
	var adjacent_targets := _find_adjacent_combat_targets(unit, all_units)
	var reachable_targets := _find_reachable_combat_targets(unit, unit_manager, all_units, reachable_coords, axis, adjacent_targets)

	_add_attack_action(actions, adjacent_targets["enemies"], reachable_targets["enemies"])
	_add_aid_action(actions, adjacent_targets["allies"], reachable_targets["allies"])

static func _add_attack_action(actions: Array[Dictionary], enemies: Array, reachable_enemies: Array) -> void:
	var attack_adjacent_count = enemies.size()
	var attack_reachable_count = reachable_enemies.size()
	if attack_adjacent_count > 0 or attack_reachable_count > 0:
		var attack_action: Dictionary = {
			"type": "attack",
			"label": _format_action_label("Attack", attack_adjacent_count, attack_reachable_count),
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

static func _add_aid_action(actions: Array[Dictionary], allies: Array, reachable_allies: Array) -> void:
	var aid_adjacent_count = allies.size()
	var aid_reachable_count = reachable_allies.size()
	if aid_adjacent_count > 0 or aid_reachable_count > 0:
		var aid_action: Dictionary = {
			"type": "aid",
			"label": _format_action_label("Aid Ally", aid_adjacent_count, aid_reachable_count),
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

static func _append_goal_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var goal := _find_goal_at_position(unit, action_origin)
	_add_goal_action(actions, goal)

static func _find_goal_at_position(unit: Unit, action_origin: Vector2i) -> Node:
	var goal_manager = unit._goal_manager
	if not goal_manager:
		return null
	var goal = goal_manager.get_goal_at_cell(action_origin)
	if goal != null and goal.can_be_worked_on_by(unit):
		return goal
	return null

static func _add_goal_action(actions: Array[Dictionary], goal: Node) -> void:
	if goal:
		actions.append({
			"type": "work_on_goal",
			"label": "Work on Goal",
			"available": true,
			"target": goal
		})

static func _append_loot_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var immediate_loot := _find_immediate_loot(unit, action_origin)
	var reachable_loot := _find_reachable_loot(unit, reachable_coords, reachable_lookup, immediate_loot)
	_add_loot_action(actions, immediate_loot, reachable_loot)

static func _find_immediate_loot(unit: Unit, action_origin: Vector2i) -> Node:
	var loot_manager = unit._loot_manager
	if not loot_manager:
		return null
	var loot = loot_manager.get_loot_at(action_origin)
	if loot and loot.can_be_looted_by(unit):
		return loot
	return null

static func _find_reachable_loot(unit: Unit, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, immediate_loot: Node) -> Array:
	var reachable_loot: Array = []
	var loot_manager = unit._loot_manager
	if not loot_manager or reachable_coords.size() <= 1:
		return reachable_loot

	var loot_count = loot_manager.get_loot_count()
	for loot_index in range(loot_count):
		var loot_item = loot_manager.get_loot(loot_index)
		if loot_item == null or loot_item == immediate_loot:
			continue
		if not loot_item.can_be_looted_by(unit):
			continue
		var loot_coord = loot_manager.get_coord(loot_index)
		if reachable_lookup.has(loot_coord):
			reachable_loot.append(loot_item)
	return reachable_loot

static func _add_loot_action(actions: Array[Dictionary], immediate_loot: Node, reachable_loot: Array) -> void:
	var loot_immediate_count = 1 if immediate_loot else 0
	var loot_reachable_count = reachable_loot.size()

	if loot_immediate_count > 0 or loot_reachable_count > 0:
		var loot_action: Dictionary = {
			"type": "loot",
			"label": _format_action_label("Pick up Loot", loot_immediate_count, loot_reachable_count),
			"available": loot_immediate_count > 0
		}
		if loot_immediate_count > 0:
			loot_action["target"] = immediate_loot
		if loot_reachable_count > 0:
			loot_action["reachable"] = true
			loot_action["reachable_targets"] = reachable_loot
			loot_action["hint"] = "Move onto the loot to pick it up."
		actions.append(loot_action)

static func _append_wait_action(actions: Array[Dictionary]) -> void:
	actions.append({
		"type": "wait",
		"label": "Wait / End Turn",
		"available": true
	})

## Check if a unit can work on a goal at a position
static func can_work_on_goal(unit: Unit, pos: Vector2i) -> bool:
	if unit._goal_manager == null:
		return false

	var goal = unit._goal_manager.get_goal_at_cell(pos)
	return goal != null and goal.can_be_worked_on_by(unit)

## Check if there's loot at a position
static func has_loot_at_position(unit: Unit, pos: Vector2i) -> bool:
	if unit._loot_manager == null:
		return false

	var loot = unit._loot_manager.get_loot_at(pos)
	return loot != null and loot.can_be_looted_by(unit)

static func _has_reachable_adjacent(reachable_coords: Array, target_coord: Vector2i, axis: int, action_range: float) -> bool:
	for coord in reachable_coords:
		if coord == target_coord:
			continue
		var distance = HexNavigator.get_hex_distance(coord, target_coord, axis)
		if distance > 0 and distance <= action_range:
			return true
	return false

static func _can_reach_coord(reachable_coords: Array, target_coord: Vector2i) -> bool:
	for coord in reachable_coords:
		if coord == target_coord:
			return true
	return false

static func _format_action_label(base: String, adjacent_count: int, reachable_count: int) -> String:
	var detail: Array[String] = []
	if adjacent_count > 0:
		detail.append("%d adjacent" % adjacent_count)
	if reachable_count > 0:
		detail.append("%d reachable" % reachable_count)
	if detail.is_empty():
		return base
	return "%s (%s)" % [base, ", ".join(detail)]
