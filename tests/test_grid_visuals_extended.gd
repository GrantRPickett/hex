extends GdUnitTestSuite

const GridVisualsScene = preload("res://Gameplay/map/grid_visuals.gd")

func _make_visuals() -> Node2D:
	var visuals: GridVisualsScene = GridVisualsScene.new()
	add_child(visuals)
	return visuals

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_update_hover_indicator() -> void:
	var visuals = _make_visuals()
	var grid: TileMapLayer = TileMapLayer.new() # Mock grid
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)

	# Initial setup is needed so the polygon has points before positioning
	visuals.setup_hex_shape(Vector2(64, 64), grid)

	# Test outside bounds (should be invisible)
	var mock_map: Node = Node.new()
	mock_map.set_script(preload("res://Gameplay/map/terrain_map.gd"))
	var map_inst = mock_map.get_script().new()
	map_inst.load_from_rows(["G"]) # 1x1 map

	visuals.update_hover_indicator(Vector2(500, 500), grid, null, map_inst)
	assert_bool(visuals._hover_indicator.visible).is_false()

	# Test inside bounds (should be visible)
	visuals.update_hover_indicator(Vector2(0, 0), grid, null, map_inst)
	assert_bool(visuals._hover_indicator.visible).is_true()

	grid.free()

func test_update_terrain_overlay() -> void:
	var visuals = _make_visuals()
	var grid: TileMapLayer = TileMapLayer.new() # Mock grid
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)

	var mock_map: Node = Node.new()
	mock_map.set_script(preload("res://Gameplay/map/terrain_map.gd"))
	var map_inst = mock_map.get_script().new()
	map_inst.load_from_rows(["GGG", "G G"])

	visuals.update_terrain_overlay(grid, map_inst)

	# Since it creates a child polygon for each valid coordinate, we check the child count
	# There are 5 "G"s (valid coordinates) in the map.
	assert_int(visuals._terrain_overlay_root.get_child_count()).is_equal(5)

	grid.free()

func test_toggle_enemy_range_view() -> void:
	var visuals = _make_visuals()
	assert_bool(visuals.is_enemy_range_visible()).is_false()
	visuals.toggle_enemy_range_view()
	assert_bool(visuals.is_enemy_range_visible()).is_true()
	assert_object(visuals._enemy_range_root).is_not_null()
	assert_bool(visuals._enemy_range_root.visible).is_true()
	visuals.toggle_enemy_range_view()
	assert_bool(visuals.is_enemy_range_visible()).is_false()
	assert_bool(visuals._enemy_range_root.visible).is_false()

func test_show_threatened_path_hex() -> void:
	var visuals = _make_visuals()
	var grid: TileMapLayer = TileMapLayer.new() # Mock grid
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)
	assert_bool(visuals._threatened_path_hex.visible).is_false()
	visuals.show_threatened_path_hex(Vector2i(1, 1), grid)
	assert_bool(visuals._threatened_path_hex.visible).is_true()
	grid.free()

const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_update_path_preview() -> void:
	var visuals = _make_visuals()
	var grid: TileMapLayer = TileMapLayer.new() # Mock grid
	grid.tile_set = TileSet.new()
	grid.tile_set.tile_size = Vector2i(64, 64)

	var um: Stubs.FakeUnitManager = Stubs.FakeUnitManager.new()
	var tm: Stubs.FakeTerrainMap = Stubs.FakeTerrainMap.new()

	visuals.update_path_preview(Vector2(0, 0), grid, um, tm)
	assert_bool(visuals._path_line.visible).is_false()

	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = 0
	um._units.append(unit)
	um._selected_index = 0

	visuals.update_path_preview(Vector2(0, 0), grid, um, tm)
	assert_object(visuals._path_line).is_not_null()
	grid.free()
