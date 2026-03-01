class_name GridUtils
extends RefCounted

static func dims_of(level: Level) -> Dictionary:
	if level == null or level.terrain_data == null:
		return {"width": 1, "height": 1, "axis": 1}
	return {
		"width": max(1, int(level.terrain_data.grid_width)),
		"height": max(1, int(level.terrain_data.grid_height)),
		"axis": int(level.hex_offset_axis),
	}

static func is_passable(terrain_map: TerrainMap, coord: Vector2i, level: Level) -> bool:
	if terrain_map == null:
		return true
	var dims := dims_of(level)
	if not CoordValidator.is_in_bounds(coord, int(dims.width), int(dims.height)):
		return false
	if not terrain_map.has_method("is_passable"):
		return true
	return terrain_map.is_passable(coord)
