extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const MovementRangeCalculator := preload("res://Gameplay/movement_range_calculator.gd")

func test_compute_limits_by_cost() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows(["GRM"], 3, 1)
	var calculator := MovementRangeCalculator.new()
	var reachable := calculator.compute(Vector2i(0, 0), 2, terrain_map)
	assert_bool(reachable.has(Vector2i(1, 0))).is_true()
	assert_bool(reachable.has(Vector2i(2, 0))).is_false()
	terrain_map.load_from_rows([])
	terrain_map.load_from_rows([])

func test_compute_blocks_impassable_tiles() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows(["GWG"], 3, 1)
	var calculator := MovementRangeCalculator.new()
	var reachable := calculator.compute(Vector2i(0, 0), 3, terrain_map)
	assert_bool(reachable.has(Vector2i(2, 0))).is_false()
