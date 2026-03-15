## Service for unified spatial queries across units, loot, and terrain.
## 
## This service combines data from UnitManager, LootManager, and TerrainMap
## to provide a single interface for "what is at this coordinate?".
class_name GridQueryService
extends RefCounted

var _unit_manager: UnitManager
var _loot_manager: LootManager
var _terrain_map: TerrainMap
var _task_manager: TaskManager
var _grid: TileMapLayer

func setup(unit_manager: UnitManager, loot_manager: LootManager, terrain_map: TerrainMap, task_manager: TaskManager = null, grid: TileMapLayer = null) -> void:
	_unit_manager = unit_manager
	_loot_manager = loot_manager
	_terrain_map = terrain_map
	_task_manager = task_manager
	_grid = grid

# --- Coordinate Mapping ---

## Returns the grid location for a world position.
func world_to_map(world_pos: Vector2) -> Vector2i:
	if not is_instance_valid(_grid): return GameConstants.INVALID_COORD
	return _grid.local_to_map(_grid.to_local(world_pos))

## Returns the local world position for a map coordinate.
func map_to_world(map_coord: Vector2i) -> Vector2:
	if not is_instance_valid(_grid): return Vector2.ZERO
	return _grid.map_to_local(map_coord)

## Returns the distance between two map coordinates.
func get_distance(a: Vector2i, b: Vector2i) -> int:
	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	if is_instance_valid(_grid) and _grid.tile_set:
		axis = _grid.tile_set.tile_offset_axis
	return HexLib.get_distance(a, b, axis)

## Snaps a Node2D to the grid and returns its new coordinate.
func snap_to_grid(node: Node2D) -> Vector2i:
	if not is_instance_valid(_grid): return GameConstants.INVALID_COORD
	var coord = _grid.local_to_map(_grid.to_local(node.global_position))
	node.global_position = _grid.to_global(_grid.map_to_local(coord))
	return coord

# --- Unit Queries ---

## Returns true if the coordinate is occupied by a unit.
func is_unit_at(coord: Vector2i, ignore_unit: Unit = null) -> bool:
	if not is_instance_valid(_unit_manager): return false
	var unit = _unit_manager.get_unit_at_coord(coord)
	return is_instance_valid(unit) and unit != ignore_unit

## Returns the unit at the given coordinate, if any.
func get_unit_at(coord: Vector2i) -> Unit:
	if not is_instance_valid(_unit_manager): return null
	return _unit_manager.get_unit_at_coord(coord)

# --- Loot Queries ---

## Returns true if there is loot at the given coordinate.
func is_loot_at(coord: Vector2i) -> bool:
	if not is_instance_valid(_loot_manager): return false
	return _loot_manager.has_loot_at(coord)

## Returns the loot at the given coordinate, if any.
func get_loot_at(coord: Vector2i) -> Loot:
	if not is_instance_valid(_loot_manager): return null
	return _loot_manager.get_loot_at(coord)

# --- Terrain Queries ---

## Returns the terrain at the given coordinate.
func get_terrain(coord: Vector2i) -> TerrainTile:
	if not is_instance_valid(_terrain_map): return null
	return _terrain_map.get_terrain(coord)

## Returns true if the coordinate is passable (terrain check).
func is_passable(coord: Vector2i) -> bool:
	if not is_instance_valid(_terrain_map): return true
	return _terrain_map.is_passable(coord)

# --- Location Queries ---

## Returns the location (Target) at the given coordinate, if any.
func get_location_at(coord: Vector2i) -> Location:
	if not is_instance_valid(_task_manager): return null
	return _task_manager.get_location_at(coord)

# --- Unified Queries ---

## Returns true if a unit cannot move into this coordinate.
## (Checks terrain passability and unit occupancy).
func is_blocked(coord: Vector2i, ignore_unit: Unit = null) -> bool:
	if not is_passable(coord): return true
	return is_unit_at(coord, ignore_unit)

## Returns all interactable objects at a coordinate.
## Returns a Dictionary with keys: "unit", "loot", "location".
func get_all_at(coord: Vector2i) -> Dictionary:
	return {
		"unit": get_unit_at(coord),
		"loot": get_loot_at(coord),
		"location": get_location_at(coord),
		"terrain": get_terrain(coord)
	}

## Returns neighbors for a coordinate based on the current terrain map.
func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
	if not is_instance_valid(_terrain_map): return []
	return _terrain_map.get_neighbors(coord)

## Finds the nearest empty coordinate around a point.
func get_nearest_empty_coord(requested_coord: Vector2i, max_radius: int = 5) -> Vector2i:
	if not is_instance_valid(_unit_manager):
		return requested_coord
	
	# Check if requested coordinate is already valid (within bounds and not occupied)
	var req_valid = true
	if is_instance_valid(_terrain_map) and not _terrain_map.is_within_bounds(requested_coord):
		req_valid = false
	elif is_unit_at(requested_coord):
		req_valid = false
		
	if req_valid:
		return requested_coord

	var visited := {requested_coord: true}
	var queue := [requested_coord]
	var current_radius := 0

	# Determine axis from the manager's context (looking at first unit's map if available)
	var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var units = _unit_manager.get_units()
	if not units.is_empty() and is_instance_valid(units[0].grid_map) and units[0].grid_map.tile_set:
		axis = units[0].grid_map.tile_set.tile_offset_axis

	while not queue.is_empty():
		var layer_size = queue.size()
		for i in range(layer_size):
			var current = queue.pop_front()
			
			# Check if this cell is valid (within bounds and not occupied)
			var is_valid = true
			if is_instance_valid(_terrain_map) and not _terrain_map.is_within_bounds(current):
				is_valid = false
			elif is_unit_at(current):
				is_valid = false
				
			if is_valid:
				return current

			var offsets = HexLib.get_neighbor_offsets(current, axis)
			for offset in offsets:
				var neighbor = current + offset
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)

		current_radius += 1
		if current_radius > max_radius:
			break

	return GameConstants.INVALID_COORD
