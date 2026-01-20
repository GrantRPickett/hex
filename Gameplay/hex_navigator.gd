class_name HexNavigator
extends Node

const DIRECTION_ACTIONS := {
	"move_w": -PI/2,
	"move_e": -PI/6,
	"move_d": PI/6,
	"move_s": PI/2,
	"move_a": 5*PI/6,
	"move_q": -5*PI/6
}

const EVEN_COLUMN_NEIGHBORS := [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0),
	Vector2i(0, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const ODD_COLUMN_NEIGHBORS := [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
]
const EVEN_ROW_NEIGHBORS := [
	Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]
const ODD_ROW_NEIGHBORS := [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1),
]

var _action_vectors: Dictionary = {}

func get_direction_map(coord: Vector2i, grid) -> Dictionary:
	var map := {}
	if not is_instance_valid(grid):
		return map

	if not grid.get("tile_set"):
		return map

	var candidates := []
	var axis = grid.tile_set.tile_offset_axis
	var offsets = get_neighbor_offsets(coord, axis)
	var surrounding_cells: Array[Vector2i] = []
	for offset in offsets:
		surrounding_cells.append(coord + offset)

	for n_cell in surrounding_cells:
		var diff := n_cell - coord
		var dir: Vector2 = grid.map_to_local(n_cell) - grid.map_to_local(coord)
		candidates.append({"cell": diff, "dir": dir, "angle": dir.angle()})

	for action in DIRECTION_ACTIONS:
		var target_angle: float = DIRECTION_ACTIONS[action]
		var best_cand = null
		var min_dist = INF

		for cand in candidates:
			var angle_diff = wrapf(cand.angle - target_angle, -PI, PI)
			if abs(angle_diff) < min_dist:
				min_dist = abs(angle_diff)
				best_cand = cand

		if best_cand:
			map[action] = best_cand.cell

	return map

func cache_analog_vectors(grid) -> void:
	_action_vectors.clear()
	if not is_instance_valid(grid):
		return

	var center := Vector2i(0, 0)
	var center_pos: Vector2 = grid.map_to_local(center)
	var dir_map := get_direction_map(center, grid)

	for action in dir_map:
		var neighbor_cell = center + dir_map[action]
		var neighbor_pos = grid.map_to_local(neighbor_cell)
		_action_vectors[action] = (neighbor_pos - center_pos).normalized()

func map_action_by_camera(action: String, coord: Vector2i, rotation: float, grid) -> String:
	if _action_vectors.is_empty():
		cache_analog_vectors(grid)

	if not _action_vectors.has(action):
		return action

	var original_vec: Vector2 = _action_vectors[action]
	var target_world_vec := original_vec.rotated(rotation)
	return _get_closest_action(target_world_vec)

func get_action_from_joy_axis(axis: Vector2, rotation: float, coord: Vector2i, grid) -> String:
	if _action_vectors.is_empty():
		cache_analog_vectors(grid)

	if axis.length_squared() < 0.1:
		return ""

	var target_world_vec := axis.rotated(rotation)
	return _get_closest_action(target_world_vec)

func _get_closest_action(target_vec: Vector2) -> String:
	var best_action := ""
	var max_dot := -2.0

	for action in _action_vectors:
		var vec: Vector2 = _action_vectors[action]
		var dot := vec.dot(target_vec)
		if dot > max_dot:
			max_dot = dot
			best_action = action

	return best_action

static func get_hex_distance(a: Vector2i, b: Vector2i, offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> int:
	var aq := 0
	var ar := 0
	var bq := 0
	var br := 0

	if offset_axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		aq = a.x
		ar = a.y - (a.x >> 1)
		bq = b.x
		br = b.y - (b.x >> 1)
	else:
		aq = a.x - (a.y >> 1)
		ar = a.y
		bq = b.x - (b.y >> 1)
		br = b.y

	return int(max(abs(aq - bq), max(abs(ar - br), abs((-aq - ar) - (-bq - br)))))

static func get_neighbor_offsets(coord: Vector2i, offset_axis: int) -> Array:
	if offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		return EVEN_ROW_NEIGHBORS if coord.y % 2 == 0 else ODD_ROW_NEIGHBORS
	return EVEN_COLUMN_NEIGHBORS if coord.x % 2 == 0 else ODD_COLUMN_NEIGHBORS
