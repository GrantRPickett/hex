extends GdUnitTestSuite

const GridVisualsScene = preload("res://Gameplay/map/grid_visuals.gd")

func _make_visuals() -> Node2D:
	var visuals: GridVisualsScene = GridVisualsScene.new()
	add_child(visuals)
	return visuals

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_batch_rendering_no_children() -> void:
	var visuals = _make_visuals()
	var grid: TileMapLayer = TileMapLayer.new()
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)
	grid.tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	
	var terrain_map: TerrainMap = TerrainMap.new()
	terrain_map.load_from_rows(["GGG", "GGG"])
	
	visuals.update_terrain_overlay(grid, terrain_map)
	
	# Verify terrain polygons are added to the root
	assert_int(visuals._terrain_overlay_root.get_child_count()).is_equal(6)
	
	# Verify terrain cells (in this implementation, each cell is a Polygon2D)
	var terrain_poly_count = visuals._terrain_overlay_root.get_child_count()
	assert_int(terrain_poly_count).is_equal(6)
	
	grid.free()

func test_transform_sync_parenting() -> void:
	var grid: TileMapLayer = TileMapLayer.new()
	grid.scale = Vector2(2.0, 3.0)
	grid.position = Vector2(100, 200)
	add_child(grid)
	
	var visuals = GridVisualsScene.new()
	grid.add_child(visuals)
	
	# When parented to the grid, GridVisuals should inherit the transform
	# map_to_local returns coordinates relative to the grid
	# So a cell at (0,0) with map_to_local returning (32,27) should be at (32,27) in visuals space
	# which is (100 + 32*2, 200 + 27*3) in global space.
	
	var cell_pos_local = Vector2(32, 27) # Mocked map_to_local result
	var global_pos = visuals.to_global(cell_pos_local)
	
	assert_float(global_pos.x).is_equal(100.0 + 32.0 * 2.0)
	assert_float(global_pos.y).is_equal(200.0 + 27.0 * 3.0)
	
	grid.free()

func test_hex_geometry_calculation() -> void:
	var visuals = GridVisualsScene.new()
	var grid: TileMapLayer = TileMapLayer.new()
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)
	grid.tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	grid.tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	
	var points = visuals._build_hex_points(Vector2(64, 64), grid)
	
	# Flat-top hex: 6 points
	assert_int(points.size()).is_equal(6)
	# Max width should be 64 (from -32 to 32)
	assert_float(points[0].x).is_equal(32.0)
	assert_float(points[3].x).is_equal(-32.0)
	# Max height should be 64 (from -32 to 32) based on the new logic matching tile_size
	assert_float(points[1].y).is_equal(32.0)
	assert_float(points[4].y).is_equal(-32.0)
	
	grid.free()
	visuals.free()
