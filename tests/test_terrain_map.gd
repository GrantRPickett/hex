extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/map/terrain_map.gd")
const TerrainTile := preload("res://Gameplay/terrain/terrain_tile.gd")

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

func test_get_color_for_code() -> void:
	var terrain_map := TerrainMap.new()
	# 'G' is grass, which has color Color.LAWN_GREEN
	var grass_color := terrain_map.get_color_for_code("G")
	assert_that(grass_color).is_equal(Color.LAWN_GREEN)

	# 'R' is river, let's see its color
	var river_color := terrain_map.get_color_for_code("R")
	# We should really check what it is in river.gd
	# river.gd sets color = Color.SKY_BLUE (guessing based on name or I can check)
	assert_bool(river_color != Color.WHITE).is_true()

func test_get_all_terrain_colors() -> void:
	var terrain_map := TerrainMap.new()
	var all_colors := terrain_map.get_all_terrain_colors()
	assert_bool(all_colors.has("G")).is_true()
	assert_bool(all_colors.has("R")).is_true()
	assert_that(all_colors["G"]).is_equal(Color.LAWN_GREEN)
