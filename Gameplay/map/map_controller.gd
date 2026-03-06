class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4

var _terrain_map: TerrainMap
var _grid: TileMapLayer

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

	if _grid.tile_set == null or _grid.tile_set.tile_shape != TileSet.TILE_SHAPE_HEXAGON:
		var new_ts: TileSet
		if _grid.tile_set:
			new_ts = _grid.tile_set.duplicate(true)
		else:
			new_ts = TileSet.new()
			new_ts.tile_size = Vector2i(64, 64)

		new_ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
		new_ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		if new_ts.tile_size == Vector2i.ZERO:
			new_ts.tile_size = Vector2i(96, 96)
		_grid.tile_set = new_ts

func build_grid(width: int, height: int) -> void:
	if not is_instance_valid(_grid):
		return
	_grid.clear()

	for q in range(0, width):
		for r in range(0, height):
			_grid.set_cell(Vector2i(q, r), 0, Vector2i.ZERO)
