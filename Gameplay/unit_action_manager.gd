class_name UnitActionManager
extends RefCounted

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

	# Add movement action if available
	if unit.has_move_available():
		var movement_range = unit.compute_movement_range(current_pos, terrain_map)
		if not movement_range.is_empty():
			var reachable_count = 0
			for coord in movement_range.keys():
				if not unit_manager.is_occupied(coord, unit_manager.get_unit_index(unit)):
					reachable_count += 1
			if reachable_count > 0:
				actions.append({
					"type": "move",
					"label": "Move (%d spaces)" % reachable_count,
					"available": true
				})

	# Add action options
	if unit.has_action_available():
		var adjacent_units = unit.get_adjacent_units(all_units)
		var enemies = []
		var allies = []

		for adjacent_unit in adjacent_units:
			if adjacent_unit == unit:
				continue
			if adjacent_unit.faction != unit.faction and adjacent_unit.willpower > 0:
				enemies.append(adjacent_unit)
			elif adjacent_unit.faction == unit.faction and adjacent_unit.willpower < adjacent_unit.max_willpower:
				allies.append(adjacent_unit)

		# Attack action
		if not enemies.is_empty():
			actions.append({
				"type": "attack",
				"label": "Attack (%d enemies)" % enemies.size(),
				"available": true,
				"targets": enemies,
				"target": enemies[0]
			})

		# Aid action
		if not allies.is_empty():
			actions.append({
				"type": "aid",
				"label": "Aid Ally (%d allies)" % allies.size(),
				"available": true,
				"targets": allies,
				"target": allies[0]
			})

		# Work on goal
		var goal = unit._goal_manager.get_goal_at_cell(current_pos) if unit._goal_manager else null
		if goal and goal.can_be_worked_on_by(unit):
			actions.append({
				"type": "work_on_goal",
				"label": "Work on Goal",
				"available": true,
				"target": goal
			})

		# Loot action
		var loot = unit._loot_manager.get_loot_at(current_pos) if unit._loot_manager else null
		if loot and loot.can_be_looted_by(unit):
			actions.append({
				"type": "loot",
				"label": "Pick up Loot",
				"available": true,
				"target": loot
			})

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
