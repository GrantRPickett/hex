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
	if not unit.res.has_action_available():
		return false

	var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
	var action_origin: Vector2i = reach_state.action_origin

	# 1. Location-based
	var immediate_location = TargetDiscoveryService.get_immediate_location(unit, action_origin)
	if immediate_location != null:
		return true

	# 2. Lootable objects
	var immediate_loot = TargetDiscoveryService.get_immediate_loot(unit, action_origin, unit.get_loot_manager())
	if immediate_loot != null:
		return true

	# 3. Unit-based actions (Combat, Aid, Persuasion)
	var near_targets = TargetDiscoveryService.discover_nearby(action_origin, GameConstants.AI.GRID_ADJACENCY_THRESHOLD, [TargetDiscoveryService.UNIT], {
		"unit_manager": unit_manager,
		"source_unit": unit
	})
	var near_units: Dictionary = near_targets.get(TargetDiscoveryService.UNIT, {})

	if not near_units.get("enemies", []).is_empty():
		return true
	if not near_units.get("allies", []).is_empty():
		return true

	# Check for persuadable neutrals
	for neutral: Unit in near_units.get("neutrals", []):
		if TargetDiscoveryService.is_convincable(neutral):
			return true

	return false
