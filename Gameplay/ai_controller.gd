class_name AIController
extends Node

var _unit_manager: UnitManager
var _map_controller: MapController
var _combat_system: CombatSystem
var _unit_controller: UnitController

func setup(unit_manager: UnitManager, map_controller: MapController, combat_system: CombatSystem, unit_controller: UnitController) -> void:
	_unit_manager = unit_manager
	_map_controller = map_controller
	_combat_system = combat_system
	_unit_controller = unit_controller

func execute_turn(ai_unit: Unit) -> void:
	if not is_instance_valid(ai_unit) or ai_unit.willpower <= 0:
		return

	var targets = _unit_manager._units.filter(func(u): return u.faction == Unit.Faction.PLAYER and u.willpower > 0)
	if targets.is_empty():
		return

	# Find closest target
	var start_pos = ai_unit.get_grid_location()
	var best_target: Unit = null
	var min_dist = 9999.0

	for target in targets:
		var dist = Vector2(start_pos).distance_to(Vector2(target.get_grid_location()))
		if dist < min_dist:
			min_dist = dist
			best_target = target

	if best_target == null:
		return

	# Calculate path
	var terrain_map = _map_controller.get_terrain_map()
	var target_pos = best_target.get_grid_location()

	# We want to move adjacent to the target, not ON the target
	# But get_path_to_coord expects a reachable tile.
	# Simple approach: Path to target, then stop 1 tile short.
	# Better approach: Find adjacent tiles to target, pick closest reachable.

	var path = ai_unit.get_path_to_coord(target_pos, terrain_map)

	# If path is empty, maybe target is too far or blocked.
	# Try to move towards it anyway? For now, just skip if no path found.
	if path.is_empty():
		# Fallback: Try to find path to neighbors of target
		for neighbor in terrain_map.get_neighbors(target_pos):
			if not _unit_manager.is_occupied(neighbor):
				path = ai_unit.get_path_to_coord(neighbor, terrain_map)
				if not path.is_empty():
					break

	# Execute movement
	for cell in path:
		if _unit_manager.is_occupied(cell):
			break

		var cost = terrain_map.get_movement_cost(cell)
		if ai_unit.get_remaining_movement_points() >= cost:
			var idx = _unit_manager._units.find(ai_unit)
			_unit_controller.set_coord(idx, cell)
			ai_unit.consume_move(cost)
			await get_tree().create_timer(0.2).timeout
		else:
			break

	# Attack if adjacent
	if ai_unit.get_adjacent_units(targets).has(best_target):
		_combat_system.execute_combat(ai_unit, best_target, 0) # Default pair 0 for now