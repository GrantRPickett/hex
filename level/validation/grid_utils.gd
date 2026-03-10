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
	if not GridService.is_in_bounds(coord, int(dims.width), int(dims.height)):
		return false
	if not terrain_map.has_method("is_passable"):
		return true
	return terrain_map.is_passable(coord)

static func find_replacement_coord(origin: Vector2i, terrain_map: TerrainMap, level: Level, occupancy: Dictionary, blocked: Array[String]) -> Vector2i:
	var dims := dims_of(level)
	var width := int(dims.width)
	var height := int(dims.height)
	var axis := int(dims.axis)

	var start: Vector2i = Vector2i(clamp(origin.x, 0, width - 1), clamp(origin.y, 0, height - 1))
	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}

	queue.append(start)
	visited[GridService.key_of(start)] = true

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var key: String = GridService.key_of(current)
		var occupant_type: String = occupancy.get(key, "")
		var blocked_here: bool = occupant_type != "" and blocked.has(occupant_type)

		if not blocked_here and is_passable(terrain_map, current, level):
			return current

		for offset: Vector2i in HexNavigator.get_neighbor_offsets(current, axis):
			var next: Vector2i = current + offset
			if not GridService.is_in_bounds(next, width, height):
				continue
			var next_key: String = GridService.key_of(next)
			if visited.has(next_key):
				continue
			visited[next_key] = true
			queue.append(next)

	return Vector2i(-1, -1)
