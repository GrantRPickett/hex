extends GdUnitTestSuite

var _calculator: MovementRangeCalculator
var _mock_terrain: RefCounted

class MockTerrainMap extends RefCounted:
	func is_within_bounds(coord: Vector2i) -> bool:
		return coord.x >= 0 and coord.x < 10 and coord.y >= 0 and coord.y < 10

	func is_passable(_coord: Vector2i) -> bool:
		return true

	func get_movement_cost(_coord: Vector2i) -> int:
		return 1

	func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
		var neighbors: Array[Vector2i] = []
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var neighbor = Vector2i(coord.x + dx, coord.y + dy)
				if is_within_bounds(neighbor):
					neighbors.append(neighbor)
		return neighbors

class ThreatGraphTerrainMap extends RefCounted:
	func is_within_bounds(_coord: Vector2i) -> bool:
		return true

	func is_passable(_coord: Vector2i) -> bool:
		return true

	func get_movement_cost(_coord: Vector2i) -> int:
		return 1

	func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
		var map: Dictionary = {
			Vector2i(0, 0): [Vector2i(1, 0), Vector2i(0, 1)],
			Vector2i(1, 0): [Vector2i(2, 0)],
			Vector2i(2, 0): [Vector2i(2, 1)],
			Vector2i(0, 1): [Vector2i(1, 1)],
			Vector2i(1, 1): [Vector2i(2, 1)],
			Vector2i(2, 1): []
		}
		return map.get(coord, [] as Array[Vector2i])

	func get_offset_axis() -> int:
		return TileSet.TILE_OFFSET_AXIS_VERTICAL

func before_test() -> void:
	_calculator = auto_free(MovementRangeCalculator.new())
	_mock_terrain = auto_free(MockTerrainMap.new())

func test_find_path_same_start_and_target() -> void:
	var path = _calculator.find_path(Vector2i(0, 0), Vector2i(0, 0), {}, _mock_terrain)

	assert_int(path.size()).is_equal(0)

func test_find_path_target_not_reachable() -> void:
	var reachable: Dictionary = {}
	var path = _calculator.find_path(Vector2i(1, 1), Vector2i(0, 0), reachable, _mock_terrain)

	assert_int(path.size()).is_equal(0)

func test_find_path_simple() -> void:
	# Create a simple reachable dictionary with a path from (0,0) to (1,0)
	var reachable: Dictionary = {
		Vector2i(1, 0): 4,
		Vector2i(2, 0): 3
	}

	var path = _calculator.find_path(Vector2i(1, 0), Vector2i(0, 0), reachable, _mock_terrain)

	# Path should exist if the algorithm can trace back
	assert_object(path).is_not_null()

func test_find_path_prefers_non_threatened_hexes() -> void:
	var threat_map = auto_free(ThreatGraphTerrainMap.new())
	var reachable: Dictionary = {
		Vector2i(1, 0): 3,
		Vector2i(2, 0): 2,
		Vector2i(0, 1): 3,
		Vector2i(1, 1): 2,
		Vector2i(2, 1): 1
	}
	var threatened: Dictionary = {Vector2i(1, 0): true, Vector2i(2, 0): true}
	var path = _calculator.find_path(Vector2i(2, 1), Vector2i(0, 0), reachable, threat_map, 3, threatened)
	assert_array(path).is_equal([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)])


func test_find_path_avoids_blocked_hexes() -> void:
	var terrain: ThreatGraphTerrainMap = auto_free(ThreatGraphTerrainMap.new())
	var reachable: Dictionary = {
		Vector2i(1, 0): 3,
		Vector2i(2, 0): 2,
		Vector2i(0, 1): 3,
		Vector2i(1, 1): 2,
		Vector2i(2, 1): 1
	}
	var blocked: Dictionary = {Vector2i(1, 1): true}
	var path = _calculator.find_path(Vector2i(2, 1), Vector2i(0, 0), reachable, terrain, 3, {}, blocked)
	assert_array(path).is_equal([Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])
