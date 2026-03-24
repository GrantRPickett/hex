class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4

var _terrain_map: TerrainMap
var _grid: TileMapLayer
var _threat_map: Dictionary = {}

func setup(grid: TileMapLayer) -> void:
	_grid = grid
	_terrain_map = TerrainMap.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)


func get_terrain_map() -> TerrainMap:
	return _terrain_map

func get_grid() -> TileMapLayer:
	return _grid

func on_loot_added(loot: Loot, coord: Vector2i) -> void:
	if not is_instance_valid(_grid):
		return
	if loot.get_parent() == null:
		_grid.add_child(loot)
	# Check for 'grid_map' property to identify Target behavior without circular dependency
	if "grid_map" in loot:
		loot.grid_map = _grid
		loot.position = _grid.map_to_local(coord)


func configure_tileset() -> void:
	if not is_instance_valid(_grid):
		return

	var new_ts: TileSet
	if _grid.tile_set:
		new_ts = _grid.tile_set.duplicate(true)
	else:
		new_ts = TileSet.new()
		new_ts.tile_size = GameConstants.TILE_SIZE

	new_ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	new_ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	if new_ts.tile_size == Vector2i.ZERO:
		new_ts.tile_size = GameConstants.TILE_SIZE
	
	# DYNAMICALLY SETUP GRID BASE BUT NO TEXTURES HERE
	# (Textures are handled by GridVisuals overlays for hex-clipping)
	_grid.tile_set = new_ts

func build_grid(width: int, height: int) -> void:
	if not is_instance_valid(_grid):
		return
	_grid.clear()

	for y in range(height):
		for x in range(width):
			var coord := Vector2i(x, y)
			_grid.set_cell(coord, 0, Vector2i.ZERO)

func get_threat_map() -> Dictionary:
	return _threat_map

func update_threat_map(unit_manager: UnitManager, terrain_map: TerrainMap) -> void:
	_threat_map.clear()
	if not is_instance_valid(unit_manager) or not is_instance_valid(terrain_map):
		return

	for i in range(unit_manager.get_unit_count()):
		var unit = unit_manager.get_unit(i)
		if is_instance_valid(unit) and not unit_manager.is_player_controlled(i):
			var budget = unit.movement.get_max_movement_points() if unit.movement else 0
			var reachable = unit.movement.compute_movement_range(unit.get_grid_location(), terrain_map, budget)
			for coord in reachable:
				_threat_map[coord] = true

func get_distance_to_selected(cell: Vector2i, unit_manager: UnitManager) -> String:
	var selected_idx: int = unit_manager.get_selected_index()
	if selected_idx != -1:
		var unit: Unit = unit_manager.get_unit(selected_idx)
		if is_instance_valid(unit) and is_instance_valid(_grid):
			var unit_coord: Vector2i = unit.get_grid_location()
			var axis := _grid.tile_set.tile_offset_axis if _grid.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL
			return str(HexLib.get_distance(unit_coord, cell, axis))
	return ""
