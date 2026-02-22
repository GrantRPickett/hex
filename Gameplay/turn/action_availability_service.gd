class_name ActionAvailabilityService
extends RefCounted

func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	if not is_instance_valid(unit):
		return true

	if unit.willpower <= 0:
		return true

	if _can_move_somewhere(unit, terrain_map, unit_manager):
		return false

	if _can_act_somewhere(unit, terrain_map, unit_manager):
		return false

	# Unit is completely stuck
	return true

func _can_move_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	if terrain_map == null or unit_manager == null:
		return false

	if not unit.has_move_available():
		return false

	var reach_state := ReachableStateCalculator.calculate(unit, terrain_map, unit_manager)
	return reach_state.move_spaces > 0

func _can_act_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	# If unit has actions, check if they can do anything with current or adjacent units
	if unit.has_action_available():
		var reach_state := ReachableStateCalculator.calculate(unit, terrain_map, unit_manager)
		var action_origin: Vector2i = reach_state.action_origin
		# Check if can work on location at current position
		if _can_work_on_task(unit, action_origin):
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

## Check if a unit can work on a task at a position
func _can_work_on_task(unit: Unit, pos: Vector2i) -> bool:
	if unit.get_task_manager() == null:
		return false

	var task_manager = unit.get_task_manager()
	var location = task_manager.get_location_at(pos)
	var task = null
	if location:
		task = task_manager.get_task_for_location(location)

	return task != null and task.can_be_worked_on_by(unit)

## Check if there's loot at a position
func _has_loot_at_position(unit: Unit, pos: Vector2i) -> bool:
	if unit.get_loot_manager() == null:
		return false

	var loot = unit.get_loot_manager().get_loot_at(pos)
	return loot != null and loot.can_be_looted_by(unit)
