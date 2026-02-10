class_name Target
extends Node2D

@export var sprite: Sprite2D
@export var grid_map: TileMapLayer

var _has_external_grid_coord := false
var _external_grid_coord := Vector2i(-999, -999)

func get_grid_location() -> Vector2i:
	if _has_external_grid_coord:
		return _external_grid_coord
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
		set_external_grid_coord(coord)

func set_external_grid_coord(coord: Vector2i) -> void:
	if coord == Vector2i(-999, -999):
		clear_external_grid_coord()
		return
	_has_external_grid_coord = true
	_external_grid_coord = coord

func clear_external_grid_coord() -> void:
	_has_external_grid_coord = false
	_external_grid_coord = Vector2i(-999, -999)

func has_external_grid_coord() -> bool:
	return _has_external_grid_coord

func distance_to_target(other: Target) -> int:
	if other == null:
		return 999999

	var self_has_grid : bool = _has_external_grid_coord or grid_map != null or (get_parent() is TileMapLayer)
	var other_has_grid : bool = other.has_external_grid_coord() or other.grid_map != null or (other.get_parent() is TileMapLayer)

	if self_has_grid and other_has_grid:
		var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
		var grid: TileMapLayer = grid_map
		if not grid and get_parent() is TileMapLayer:
			grid = get_parent()

		if grid and grid.tile_set:
			axis = grid.tile_set.tile_offset_axis
		elif not (grid and grid.tile_set):
			var other_grid: TileMapLayer = other.grid_map
			if not other_grid and other.get_parent() is TileMapLayer:
				other_grid = other.get_parent()
			if other_grid and other_grid.tile_set:
				axis = other_grid.tile_set.tile_offset_axis

		return HexNavigator.get_hex_distance(get_grid_location(), other.get_grid_location(), axis)

	var tile_size := 64.0
	var grid: TileMapLayer = grid_map
	if not grid and get_parent() is TileMapLayer:
		grid = get_parent()

	if grid and grid.tile_set:
		tile_size = float(grid.tile_set.tile_size.x)

	return roundi(global_position.distance_to(other.global_position) / tile_size)

func is_pixel_inside(world_pos: Vector2) -> bool:
	if sprite:
		# If a sprite is present, use its global rectangle
		var rect = sprite.get_global_rect()
		return rect.has_point(world_pos)
	else:
		# Otherwise, assume a default interaction radius around the target's position
		# This could be a placeholder or a configurable value
		var default_radius = 32.0 # Half the tile size, assuming 64x64 tiles
		return world_pos.distance_to(global_position) <= default_radius
