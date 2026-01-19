extends "res://tests/test_utils.gd"

var _mock_unit: GdUnitMock
var _mock_movement_cache: GdUnitMock

func before_test() -> void:
	# GIVEN
	_mock_unit = gdmock(Unit).create_mock()
	_mock_movement_cache = gdmock(MovementRangeCache).create_mock()
	
	# WHEN
	# Mock the internal _movement_cache of the unit
	when(_mock_unit.get_script()).then_return(preload("res://Gameplay/unit.gd")) # Needed for property access sometimes
	_mock_unit._movement_cache = _mock_movement_cache

func after_test() -> void:
	# No need to queue_free mocks explicitly if they are not added to scene tree
	pass

func test_get_path_to_coord_target_out_of_bounds() -> void:
	# GIVEN
	var target_coord = Vector2i(100, 100) # Out of bounds
	var start_coord = Vector2i(0, 0)
	var mock_terrain_map = gdmock(TerrainMap).create_mock()
	
	when(mock_terrain_map.has_method("is_within_bounds")).then_return(true)
	when(mock_terrain_map.is_within_bounds(target_coord)).then_return(false)
	
	when(_mock_unit.get_grid_location()).then_return(start_coord) # Should not be called

	# WHEN
	var path = _mock_unit.get_path_to_coord(target_coord, mock_terrain_map)

	# THEN
	assert_eq(path, [])
	verify(mock_terrain_map).is_within_bounds(target_coord)
	verify(_mock_unit, never()).get_grid_location()
	verify(_mock_movement_cache, never()).compute_range(any(Vector2i), any(TerrainMap))

func test_get_path_to_coord_successful_path() -> void:
	# GIVEN
	var target_coord = Vector2i(2, 0)
	var start_coord = Vector2i(0, 0)
	var expected_path = [Vector2i(1, 0), Vector2i(2, 0)]
	var mock_terrain_map = gdmock(TerrainMap).create_mock()
	var mock_reachable_cells = {
		Vector2i(0,0): {"cost": 0, "parent": null},
		Vector2i(1,0): {"cost": 1, "parent": Vector2i(0,0)},
		Vector2i(2,0): {"cost": 2, "parent": Vector2i(1,0)},
	}

	when(mock_terrain_map.has_method("is_within_bounds")).then_return(true)
	when(mock_terrain_map.is_within_bounds(target_coord)).then_return(true)
	
	when(_mock_unit.get_grid_location()).then_return(start_coord)
	when(_mock_movement_cache.compute_range(start_coord, mock_terrain_map)).then_return(mock_reachable_cells)

	# Mock MovementRangeCalculator to control its behavior
	var mock_calculator = gdmock(MovementRangeCalculator).create_mock()
	when(MovementRangeCalculator).new().then_return(mock_calculator) # Intercept constructor
	when(mock_calculator.find_path(target_coord, start_coord, mock_reachable_cells, mock_terrain_map)).then_return(expected_path)

	# WHEN
	var path = _mock_unit.get_path_to_coord(target_coord, mock_terrain_map)

	# THEN
	assert_eq(path, expected_path)
	verify(mock_terrain_map).is_within_bounds(target_coord)
	verify(_mock_unit).get_grid_location()
	verify(_mock_movement_cache).compute_range(start_coord, mock_terrain_map)
	verify(mock_calculator).find_path(target_coord, start_coord, mock_reachable_cells, mock_terrain_map)
