class_name ActionAvailabilityService
extends RefCounted

func is_unit_stuck(unit: Unit, terrain_map:TerrainMap, unit_manager: UnitManager) -> bool:
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

	if not unit.movement.has_move_available():
		return false

	var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
	return reach_state.move_spaces > 0

func _can_act_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	# If unit has actions, check if they can do anything with current or near units
	if unit.res.has_action_available():
		var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
		var action_origin: Vector2i = reach_state.action_origin

#		print_debug("[ActionAvailabilityService] Checking actions for %s at origin %s" % [unit.unit_name, action_origin])

		# Check if can work on location at current position
		var immediate_tasks = TargetDiscoveryService.get_immediate_tasks(unit, action_origin, unit.get_task_manager())
		if immediate_tasks.size() > 0:
#			print_debug("[ActionAvailabilityService]   Found %d immediate tasks" % immediate_tasks.size())
			return true

		var immediate_loot = TargetDiscoveryService.get_immediate_loot(unit, action_origin, unit.get_loot_manager())
		if immediate_loot != null:
#			print_debug("[ActionAvailabilityService]   Found immediate loot")
			return true

		# Check near units for combat or aid
		var near_targets = unit.query.get_near_units_categorized()
		if near_targets["enemies"].size() > 0:
#			print_debug("[ActionAvailabilityService]   Found %d near enemies" % near_targets["enemies"].size())
			return true
		if near_targets["allies"].size() > 0:
#			print_debug("[ActionAvailabilityService]   Found %d near allies" % near_targets["allies"].size())
			return true

#	print_debug("[ActionAvailabilityService] No actions found for %s" % unit.unit_name)
	return false
