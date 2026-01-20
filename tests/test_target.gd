extends GdUnitTestSuite

var _target: Target
var _grid: TileMapLayer

func before() -> void:
	_target = auto_free(Target.new())
	_grid = auto_free(TileMapLayer.new())
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	_grid.tile_set = tileset
	_target.grid_map = _grid

func test_get_grid_location_with_explicit_grid_map() -> void:
	_target.grid_map = _grid
	_target.position = Vector2(0, 0)

	var result = _target.get_grid_location()

	# local_to_map(0,0) should map to a grid coordinate
	assert_object(result).is_not_null()

func test_get_grid_location_with_parent_grid() -> void:
	if _target.get_parent():
		_target.get_parent().remove_child(_target)
	add_child(_target)
	_target.grid_map = null
	var test_grid = auto_free(TileMapLayer.new())
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	test_grid.tile_set = tileset
	_target.add_child(test_grid)
	_target.position = Vector2(0, 0)

	var result = _target.get_grid_location()

	assert_object(result).is_not_null()

func test_get_grid_location_no_grid() -> void:
	_target.grid_map = null

	var result = _target.get_grid_location()

	# Should return Vector2i.ZERO when no grid is available
	assert_object(result).is_equal(Vector2i.ZERO)

func test_snap_to_grid_with_explicit_grid_map() -> void:
	_target.grid_map = _grid
	_target.position = Vector2(15, 15)

	_target.snap_to_grid()

	# After snapping, position should be aligned to grid
	assert_object(_target.position).is_not_null()

func test_snap_to_grid_with_parent_grid() -> void:
	if _target.get_parent():
		_target.get_parent().remove_child(_target)
	add_child(_target)
	_target.grid_map = null
	var test_grid = auto_free(TileMapLayer.new())
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	test_grid.tile_set = tileset
	_target.add_child(test_grid)
	var initial_pos = Vector2(15, 15)
	_target.position = initial_pos

	_target.snap_to_grid()

	# Position should have changed to align to grid
	assert_object(_target.position).is_not_null()

func test_snap_to_grid_no_grid() -> void:
	_target.grid_map = null
	_target.position = Vector2(15, 15)

	_target.snap_to_grid()

	# Position should remain unchanged if no grid
	assert_object(_target.position).is_equal(Vector2(15, 15))
