class_name Target
extends Node2D

@export var sprite: Sprite2D
@export var grid_map: TileMapLayer

func get_grid_location() -> Vector2i:
	if grid_map:
		return grid_map.local_to_map(position)

	var parent = get_parent()
	if parent is TileMapLayer:
		return parent.local_to_map(position)
	return Vector2i(-999, -999)

func snap_to_grid() -> void:
	var grid: TileMapLayer = grid_map
	if not grid and get_parent() is TileMapLayer:
		grid = get_parent()

	if grid and grid.tile_set:
		var coord := grid.local_to_map(position)
		position = grid.map_to_local(coord)

func distance_to_target(other: Target) -> int:
	if other == null:
		return 999999

	var self_has_grid := grid_map != null or (get_parent() is TileMapLayer)
	var other_has_grid := other.grid_map != null or (other.get_parent() is TileMapLayer)

	if self_has_grid and other_has_grid:
		var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
		var grid: TileMapLayer = grid_map
		if not grid and get_parent() is TileMapLayer:
			grid = get_parent()

		if grid and grid.tile_set:
			axis = grid.tile_set.tile_offset_axis

		return HexNavigator.get_hex_distance(get_grid_location(), other.get_grid_location(), axis)

	var tile_size := 64.0
	var grid: TileMapLayer = grid_map
	if not grid and get_parent() is TileMapLayer:
		grid = get_parent()

	if grid and grid.tile_set:
		tile_size = float(grid.tile_set.tile_size.x)

	return roundi(global_position.distance_to(other.global_position) / tile_size)
