extends Resource
class_name HexUtils

static func direction_map_for_x(x: int, y: int, offset_axis: int, even: Dictionary, odd: Dictionary) -> Dictionary:
	if offset_axis == 0: # TILE_OFFSET_AXIS_HORIZONTAL (rows offset)
		return even if (y & 1) == 0 else odd
	else: # TILE_OFFSET_AXIS_VERTICAL (columns offset)
		return even if (x & 1) == 0 else odd

static func analog_vectors_for_x(x: int, y: int, offset_axis: int, even: Dictionary, odd: Dictionary) -> Dictionary:
	if offset_axis == 0: # TILE_OFFSET_AXIS_HORIZONTAL (rows offset)
		return even if (y & 1) == 0 else odd
	else: # TILE_OFFSET_AXIS_VERTICAL (columns offset)
		return even if (x & 1) == 0 else odd

static func cache_analog_vectors(grid: TileMapLayer, offset_axis: int, dirs_even: Dictionary, dirs_odd: Dictionary) -> Dictionary:
	var out := {"even": {}, "odd": {}}
	var even_origin := grid.map_to_local(Vector2i.ZERO)
	for action in dirs_even.keys():
		var d: Vector2i = dirs_even[action]
		var target := d
		var v := (grid.map_to_local(target) - even_origin).normalized()
		out["even"][action] = v
	var odd_origin_coord: Vector2i
	if offset_axis == 0: # TILE_OFFSET_AXIS_HORIZONTAL (rows offset)
		odd_origin_coord = Vector2i(0, 1)
	else: # TILE_OFFSET_AXIS_VERTICAL (columns offset)
		odd_origin_coord = Vector2i(1, 0)
	var odd_origin := grid.map_to_local(odd_origin_coord)
	for action in dirs_odd.keys():
		var d2: Vector2i = dirs_odd[action]
		var target2 := odd_origin_coord + d2
		var v2 := (grid.map_to_local(target2) - odd_origin).normalized()
		out["odd"][action] = v2
	return out

static func closest_action(vectors: Dictionary, world_vec: Vector2, min_dot := 0.25) -> String:
	if world_vec == Vector2.ZERO:
		return ""
	var n := world_vec.normalized()
	var best := ""
	var best_dot := -1.0
	for a in vectors.keys():
		var dot := n.dot(vectors[a])
		if dot > best_dot:
			best_dot = dot
			best = a
	return best if best_dot > min_dot else ""

