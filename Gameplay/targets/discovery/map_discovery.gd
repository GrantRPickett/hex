class_name MapDiscovery
extends RefCounted

## Unified spatial discovery for units, loot, and locations.

## Returns the unit at the given coordinate, if any.
static func get_unit_at(unit_manager: UnitManager, coord: Vector2i) -> Unit:
	if not is_instance_valid(unit_manager):
		return null
	return unit_manager.get_unit_at_coord(coord)

## Returns true if the coordinate is occupied by a unit (optionally ignoring one).
static func is_occupied(unit_manager: UnitManager, coord: Vector2i, ignore_index: int = -1) -> bool:
	if not is_instance_valid(unit_manager):
		return false
	return unit_manager.is_occupied(coord, ignore_index)

## Returns the loot at the given coordinate, if any.
static func get_loot_at(loot_manager: LootManager, coord: Vector2i) -> Loot:
	if not is_instance_valid(loot_manager):
		return null
	return loot_manager.get_loot_at(coord)

## Returns the location at the given coordinate, if any.
static func get_location_at(task_manager: TaskManager, coord: Vector2i) -> Location:
	if not is_instance_valid(task_manager):
		return null
	return task_manager.get_location_at(coord)

## Returns true if the coordinate is passable (terrain + bounds check).
static func is_passable(terrain_map: TerrainMap, coord: Vector2i) -> bool:
	if not is_instance_valid(terrain_map):
		return true # Assume passable if map missing? Or false for safety?
	return terrain_map.is_within_bounds(coord) and terrain_map.is_passable(coord)

## Returns the movement cost for a coordinate.
static func get_movement_cost(terrain_map: TerrainMap, coord: Vector2i) -> int:
	if not is_instance_valid(terrain_map):
		return 1
	return terrain_map.get_movement_cost(coord)

## Returns the best path to any unblocked neighbor of the target_pos.
static func find_path_to_adjacent(unit: Unit, target_pos: Vector2i, terrain_map: TerrainMap, unit_manager: UnitManager) -> Array:
	var best_path: Array = []
	var best_score: int = 9999
	if not is_instance_valid(terrain_map) or not is_instance_valid(unit) or not is_instance_valid(unit_manager):
		return best_path

	for neighbor in terrain_map.get_neighbors(target_pos):
		if unit_manager.is_occupied(neighbor):
			continue
		var path = unit.movement.get_path_to_coord(neighbor, terrain_map)
		if not path.is_empty():
			var score = path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path
