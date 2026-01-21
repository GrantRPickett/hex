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

	# If unit has moves available, check if they can go somewhere
	if unit.has_move_available():
		var movement_range = unit.compute_movement_range(unit.get_grid_location(), terrain_map)
		if not movement_range.is_empty():
			# Check if any reachable space is not occupied
			for coord in movement_range.keys():
				if not unit_manager.is_occupied(coord, unit_manager.get_unit_index(unit)):
					return false  # Can move somewhere

	# If unit has actions, check if they can do anything with current or adjacent units
	if unit.has_action_available():
		var current_pos = unit.get_grid_location()
		var all_units = unit_manager.get_units()

		# Check if can work on goal at current position
		if can_work_on_goal(unit, current_pos):
			return false

		# Check adjacent units for combat or aid
		var adjacent_units = unit.get_adjacent_units(all_units)
		for adjacent_unit in adjacent_units:
			if adjacent_unit == unit:
				continue

			# Can attack enemy
			if adjacent_unit.faction != unit.faction and adjacent_unit.willpower > 0:
				return false

			# Can aid ally
			if adjacent_unit.faction == unit.faction and adjacent_unit.willpower < adjacent_unit.max_willpower:
				return false

		# Check if can pick up loot at current position (if loot manager exists)
		if has_loot_at_position(unit, current_pos):
			return false

	# Unit is completely stuck
	return true

## Returns array of available actions for a unit
static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if not is_instance_valid(unit) or unit.willpower <= 0:
		return actions

	var current_pos = unit.get_grid_location()
	var all_units = unit_manager.get_units()
	var unit_index = unit_manager.get_unit_index(unit)
	var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	if unit.grid_map and unit.grid_map.tile_set:
		axis = unit.grid_map.tile_set.tile_offset_axis

	var reachable_coords: Array[Vector2i] = [current_pos]
	var movement_range: Dictionary = {}
	var reachable_move_spaces := 0

	if unit.has_move_available():
		movement_range = unit.compute_movement_range(current_pos, terrain_map)
		if not movement_range.is_empty():
			for coord in movement_range.keys():
				var coord_v2: Vector2i = coord
				reachable_coords.append(coord_v2)
				if not unit_manager.is_occupied(coord_v2, unit_index):
					reachable_move_spaces += 1
	if reachable_move_spaces > 0:
		actions.append({
			"type": "move",
			"label": "Move (%d spaces)" % reachable_move_spaces,
			"available": true
		})

	if unit.has_action_available():
		var adjacent_units = unit.get_adjacent_units(all_units)
		var enemies: Array = []
		var allies: Array = []

		for adjacent_unit in adjacent_units:
			if adjacent_unit == unit:
				continue
			if adjacent_unit.faction != unit.faction and adjacent_unit.willpower > 0:
				enemies.append(adjacent_unit)
			elif adjacent_unit.faction == unit.faction and adjacent_unit.willpower < adjacent_unit.max_willpower:
				allies.append(adjacent_unit)

		var reachable_enemies: Array = []
		var reachable_allies: Array = []
		if reachable_coords.size() > 1:
			for i in range(all_units.size()):
				var other: Unit = all_units[i]
				if other == null or other == unit:
					continue
				if enemies.has(other) or allies.has(other):
					continue
				var other_coord = unit_manager.get_coord(i)
				if other_coord == Vector2i(-999, -999):
					continue
				if other.faction != unit.faction and other.willpower > 0:
					if _has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range):
						reachable_enemies.append(other)
				elif other.faction == unit.faction and other.willpower < other.max_willpower:
					if _has_reachable_adjacent(reachable_coords, other_coord, axis, unit.action_range):
						reachable_allies.append(other)

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

		var goal_manager = unit._goal_manager
		var goal = goal_manager.get_goal_at_cell(current_pos) if goal_manager else null
		var reachable_goals: Array = []
		if goal_manager and reachable_coords.size() > 1:
			for goal_index in range(goal_manager.get_goal_count()):
				var goal_node = goal_manager.get_goal_node(goal_index)
				if goal_node == goal:
					continue
				if goal_node and goal_node.can_be_worked_on_by(unit):
					var goal_coord = goal_manager.get_target(goal_index)
					if _can_reach_coord(reachable_coords, goal_coord):
						reachable_goals.append(goal_node)

		var goal_immediate_count = 0
		if goal != null and goal.can_be_worked_on_by(unit):
			goal_immediate_count = 1
		var goal_reachable_count = reachable_goals.size()
		if goal_immediate_count > 0 or goal_reachable_count > 0:
			var goal_action: Dictionary = {
				"type": "work_on_goal",
				"label": _format_action_label("Work on Goal", goal_immediate_count, goal_reachable_count),
				"available": goal_immediate_count > 0
			}
			if goal_immediate_count > 0:
				goal_action["target"] = goal
			if goal_reachable_count > 0:
				goal_action["reachable"] = true
				goal_action["reachable_targets"] = reachable_goals
				goal_action["hint"] = "Move onto the goal tile to work on it."
			actions.append(goal_action)

		var loot_manager = unit._loot_manager
		var loot = loot_manager.get_loot_at(current_pos) if loot_manager else null
		var reachable_loot: Array = []
		if loot_manager and reachable_coords.size() > 1:
			for loot_index in range(loot_manager.get_loot_count()):
				var loot_item = loot_manager.get_loot(loot_index)
				if loot_item == null or loot_item == loot:
					continue
				if not loot_item.can_be_looted_by(unit):
					continue
				var loot_coord = loot_manager.get_coord(loot_index)
				if _can_reach_coord(reachable_coords, loot_coord):
					reachable_loot.append(loot_item)

		var loot_immediate_count = 0
		if loot != null and loot.can_be_looted_by(unit):
			loot_immediate_count = 1
		var loot_reachable_count = reachable_loot.size()
		if loot_immediate_count > 0 or loot_reachable_count > 0:
			var loot_action: Dictionary = {
				"type": "loot",
				"label": _format_action_label("Pick up Loot", loot_immediate_count, loot_reachable_count),
				"available": loot_immediate_count > 0
			}
			if loot_immediate_count > 0:
				loot_action["target"] = loot
			if loot_reachable_count > 0:
				loot_action["reachable"] = true
				loot_action["reachable_targets"] = reachable_loot
				loot_action["hint"] = "Move onto the loot to pick it up."
			actions.append(loot_action)

	# Skip/Wait action (always available when it's their turn)
	actions.append({
		"type": "wait",
		"label": "Wait / End Turn",
		"available": true
	})

	return actions

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
