class_name ActionAvailabilityService
extends RefCounted

func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
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

func _can_move_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	# If unit has moves available, check if they can go somewhere
	if unit.has_move_available():
		var movement_range = unit.compute_movement_range(unit.get_grid_location(), terrain_map)
		if not movement_range.is_empty():
			# Check if any reachable space is not occupied
			for coord in movement_range.keys():
				if not unit_manager.is_occupied(coord, unit_manager.get_unit_index(unit)):
					return true  # Can move somewhere
	return false

func _can_act_somewhere(unit: Unit, unit_manager: UnitManager) -> bool:
	# If unit has actions, check if they can do anything with current or adjacent units
	if unit.has_action_available():
		var current_pos = unit.get_grid_location()
		var action_origin = current_pos
		if unit.has_tentative_move():
			action_origin = unit.get_tentative_grid_coord()
		# Check if can work on goal at current position
		if _can_work_on_goal(unit, action_origin):
			return true
		if _has_loot_at_position(unit, action_origin):
			return true
		# Check adjacent units for combat or aid
		var friendlies = unit.get_friendly_units()
		var adjacent_friendlies = unit.get_adjacent_units(friendlies)
		for ally in adjacent_friendlies:
			if ally == unit: continue
			if ally.willpower < ally.max_willpower:
				return true

		var hostiles = unit.get_hostile_units()
		var adjacent_hostiles = unit.get_adjacent_units(hostiles)
		for enemy in adjacent_hostiles:
			if enemy.willpower > 0:
				return true
	return false

## Check if a unit can work on a goal at a position
func _can_work_on_goal(unit: Unit, pos: Vector2i) -> bool:
	if unit.get_goal_manager() == null:
		return false

	var goal = unit.get_goal_manager().get_goal_at_cell(pos)
	return goal != null and goal.can_be_worked_on_by(unit)

## Check if there's loot at a position
func _has_loot_at_position(unit: Unit, pos: Vector2i) -> bool:
	if unit.get_loot_manager() == null:
		return false

	var loot = unit.get_loot_manager().get_loot_at(pos)
	return loot != null and loot.can_be_looted_by(unit)
