extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const TerrainTile := preload("res://Gameplay/Terrain/terrain_tile.gd")

func test_load_from_rows_defaults_unknown_codes_to_grass() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows(["GR", "MW"], 2, 2)
	assert_bool(terrain_map.is_within_bounds(Vector2i(1, 1))).is_true()
	assert_bool(terrain_map.is_passable(Vector2i(0, 0))).is_true()
	assert_int(terrain_map.get_movement_cost(Vector2i(1, 0))).is_equal(0)
	var terrain := terrain_map.get_terrain(Vector2i(1, 0))
	assert_bool(terrain is TerrainTile).is_true()
	assert_int(terrain_map.get_movement_cost(Vector2i(1, 1))).is_equal(1)
	assert_bool(terrain_map.is_passable(Vector2i(1, 1))).is_false()

func test_out_of_bounds_returns_defaults() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows([], 3, 3)
	assert_bool(terrain_map.is_passable(Vector2i(0, 0))).is_true()
	assert_int(terrain_map.get_movement_cost(Vector2i(2, 2))).is_equal(1)
	var neighbors := terrain_map.get_neighbors(Vector2i(1, 1))
	assert_int(neighbors.size()).is_equal(6)
