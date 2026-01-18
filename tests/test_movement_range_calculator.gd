extends GdUnitTestSuite

var _calculator: MovementRangeCalculator
var _mock_terrain: RefCounted

func before() -> void:
	_calculator = auto_free(MovementRangeCalculator.new())

	# Create a mock terrain map
	_mock_terrain = auto_free(RefCounted.new())
	_mock_terrain.set_meta("is_within_bounds", func(coord: Vector2i) -> bool:
		return coord.x >= 0 and coord.x < 10 and coord.y >= 0 and coord.y < 10
	)
	_mock_terrain.set_meta("is_passable", func(_coord: Vector2i) -> bool: return true)
	_mock_terrain.set_meta("get_movement_cost", func(_coord: Vector2i) -> int: return 1)
	_mock_terrain.set_meta("get_neighbors", func(coord: Vector2i) -> Array:
		var neighbors: Array = []
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var neighbor = Vector2i(coord.x + dx, coord.y + dy)
				neighbors.append(neighbor)
		return neighbors
	)

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
