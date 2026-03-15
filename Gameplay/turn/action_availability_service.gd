class_name ActionAvailabilityService
extends RefCounted

const LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")
const TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

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

	if not unit.movement.has_move_available():
		return false

	var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
	return reach_state.move_spaces > 0

func _can_act_somewhere(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	# If unit has actions, check if they can do anything with current or near units
	if unit.res.has_action_available():
		var reach_state: ReachableState = MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
		var action_origin: Vector2i = reach_state.action_origin

		# Check if can work on location at current position
		if TaskDiscovery.get_immediate_tasks(unit, action_origin, unit.get_task_manager()).size() > 0:
			return true

		if LootDiscovery.get_immediate_loot(unit, action_origin, unit.get_loot_manager()) != null:
			return true

		# Check near units for combat or aid
		var near_targets = unit.query.get_near_units_categorized()
		if near_targets["enemies"].size() > 0 or near_targets["allies"].size() > 0:
			return true

	return false
