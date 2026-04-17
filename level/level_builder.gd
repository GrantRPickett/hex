class_name LevelBuilder
extends RefCounted

# location and Unit classes are auto-global in Godot 4

var _context: LevelBuildContext
var _terrain_map

func _init(context: LevelBuildContext) -> void:
	_context = context

func build_environment(level: Level, terrain_map: TerrainMap) -> Dictionary:
	_apply_level_settings(level, terrain_map)
	_terrain_map = terrain_map

	return {
		"grid_width": level.terrain_data.grid_width,
		"grid_height": level.terrain_data.grid_height,
	}

func spawn_global_content(level: Level, terrain_map: TerrainMap) -> void:
	const Spawner := preload("res://level/level_content_spawner.gd")
	var spawner := Spawner.new(_context, terrain_map)
	spawner.spawn_global_content(level)

func _apply_level_settings(level: Level, terrain_map: TerrainMap) -> void:
	if _context.grid == null:
		GameLogger.error(GameLogger.Category.SYSTEM, "LevelBuilder: _context.grid is NULL!")
		return

	if is_instance_valid(_context.grid.tile_set):
		var ts: TileSet = _context.grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = level.hex_offset_axis as TileSet.TileOffsetAxis
			_context.grid.tile_set = dup

	if terrain_map:
		var dims := HexLib.dims_of(level)
		terrain_map.set_offset_axis(dims.axis)
		if level.terrain_data:
			terrain_map.load_from_rows(level.terrain_data.terrain_rows, dims.width, dims.height)

func _is_location_coord_passable(coord: Vector2i) -> bool:
	if _terrain_map == null or not _terrain_map.has_method("is_passable"): return true
	return _terrain_map.is_passable(coord)
