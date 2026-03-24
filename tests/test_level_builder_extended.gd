extends GdUnitTestSuite

const LevelBuilderClass = preload("res://level/level_builder.gd")
const LevelClass = preload("res://level/level.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_build_environment() -> void:
	var context = auto_free(preload("res://tests/test_level_builder.gd").new()._make_level_build_context())
	# Give the camera
	context.camera = Camera2D.new()
	context.camera.rotation = 0

	var grid: TileMapLayer = TileMapLayer.new()
	grid.tile_set = TileSet.new()
	context.grid = grid

	var builder = auto_free(LevelBuilderClass.new(context))

	var lvl = auto_free(LevelClass.new())
	lvl.initial_rotation = 1.0
	lvl.hex_offset_axis = 1
	var td = auto_free(LevelTerrainData.new())
	td.grid_width = 10
	td.grid_height = 10
	td.terrain_rows = []
	lvl.terrain_data = td

	var tm = auto_free(Stubs.FakeTerrainMap.new())

	var dict = builder.build_environment(lvl, tm)
	assert_int(dict.get("grid_width")).is_equal(10)
	assert_int(dict.get("grid_height")).is_equal(10)

func test_spawn_global_content() -> void:
	var context = auto_free(preload("res://tests/test_level_builder.gd").new()._make_level_build_context())
	var builder = auto_free(LevelBuilderClass.new(context))
	var lvl = auto_free(LevelClass.new())
	var tm = auto_free(Stubs.FakeTerrainMap.new())

	# Just test it runs without crashing
	builder.spawn_global_content(lvl, tm)
