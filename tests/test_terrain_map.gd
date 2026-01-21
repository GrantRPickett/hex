extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const TerrainTile := preload("res://Gameplay/Terrain/terrain_tile.gd")

func test_load_from_rows_defaults_unknown_codes_to_grass() -> void:
	var terrain_map := TerrainMap.new()
	# Game coord (1,1) is data index (1,1)
	terrain_map.load_from_rows(["??", "?R"], 2, 2)
	assert_bool(terrain_map.is_within_bounds(Vector2i(1, 1))).is_true()
	assert_bool(terrain_map.is_within_bounds(Vector2i(0, 0))).is_false()
	# (1,1) is 'R' in ["??", "?R"]
	assert_that(terrain_map.get_code(Vector2i(1, 1))).is_equal("R")
	terrain_map.load_from_rows([])

func test_out_of_bounds_returns_null_terrain() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows([], 3, 3)
	var terrain := terrain_map.get_terrain(Vector2i(0, 0))
	assert_bool(terrain is TerrainTile.NullTerrain).is_true()
	assert_bool(terrain.passable).is_false()
	assert_int(terrain_map.get_movement_cost(Vector2i(0, 0))).is_equal(terrain_map.NON_PASSABLE_COST)
	terrain_map.load_from_rows([])

func test_version_increments_on_load() -> void:
	var terrain_map := TerrainMap.new()
	var initial := terrain_map.get_version()
	terrain_map.load_from_rows(["??", "??", "?G"], 2, 3)
	var after_first := terrain_map.get_version()
	terrain_map.load_from_rows(["??", "??", "??", "??", "G"], 2, 5)
	var after_second := terrain_map.get_version()
	assert_bool(after_first > initial).is_true()
	assert_bool(after_second > after_first).is_true()
	terrain_map.load_from_rows([])

func test_get_neighbors_respects_offset_axis() -> void:
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows(["???", "???", "???", "???", "???", "???", "???", "?G?"], 3, 8)
	var vertical := terrain_map.get_neighbors(Vector2i(1, 1))
	# Relative offsets are same, just starting from (1,1)
	assert_that(vertical).is_equal([
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(1, 2),
		Vector2i(0, 1),
		Vector2i(0, 0),
	])
	terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_HORIZONTAL)
	var horizontal_even := terrain_map.get_neighbors(Vector2i(0, 0))
	assert_that(horizontal_even).is_equal([
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(-1, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	])
	var horizontal_odd := terrain_map.get_neighbors(Vector2i(0, 1))
	assert_that(horizontal_odd).is_equal([
		Vector2i(1, 1),
		Vector2i(1, 0),
		Vector2i(0, 0),
		Vector2i(-1, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
	])
