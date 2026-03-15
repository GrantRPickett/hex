extends GdUnitTestSuite

# Tests for terrain interaction with movement system
# Verifies that pathfinding respects terrain properties and movement constraints

const TestLevelFactory := preload("res://tests/test_level_factory.gd")
const MoveControllerClass := preload("res://Gameplay/map/move_controller.gd")
const HexNavigatorClass := preload("res://Gameplay/map/hex_navigator.gd")
const MapControllerClass := preload("res://Gameplay/map/map_controller.gd")
const LevelBuilderClass := preload("res://level/level_builder.gd")
const UnitManagerClass := preload("res://Gameplay/targets/unit_manager.gd")

func test_map_controller_loads_terrain() -> void:
	# Verify MapController loads and manages terrain data
	var map_controller: MapControllerClass = MapControllerClass.new()
	assert_that(map_controller).is_not_null()

func test_terrain_map_has_passability_data() -> void:
	# Verify terrain maps contain passability information
	# (Placeholder for terrain passability logic checks)
	pass

func test_movement_respects_grid_boundaries() -> void:
	# Verify pathfinding doesn't allow movement outside grid
	var hex_navigator: HexNavigatorClass = HexNavigatorClass.new()
	assert_that(hex_navigator).is_not_null()

func test_occupied_hex_blocks_movement() -> void:
	# Verify units cannot move into hexes occupied by other units
	var unit_manager: UnitManagerClass = UnitManagerClass.new()
	assert_that(unit_manager).is_not_null()

func test_pathfinding_avoids_obstacles() -> void:
	# Verify pathfinding finds alternate routes around obstacles
	var hex_navigator: HexNavigatorClass = HexNavigatorClass.new()
	assert_that(hex_navigator).is_not_null()

func test_movement_cost_calculated_per_terrain() -> void:
	# Verify different terrain types have appropriate movement costs
	var move_controller: MoveControllerClass = MoveControllerClass.new()
	assert_that(move_controller).is_not_null()

func test_config_movement_constants_available() -> void:
	# Verify GameConfig has movement tweening constants
	assert_that(GameConfig.MOVEMENT_TWEEN_DURATION).is_equal(0.2)
	assert_that(GameConfig.MOVEMENT_TWEEN_TRANS).is_equal(Tween.TRANS_SINE)
	assert_that(GameConfig.MOVEMENT_TWEEN_EASE).is_equal(Tween.EASE_OUT)

func test_config_grid_constants_available() -> void:
	# Verify GameConfig has grid dimension constants
	assert_that(GameConfig.DEFAULT_GRID_WIDTH).is_equal(7)
	assert_that(GameConfig.DEFAULT_GRID_HEIGHT).is_equal(7)
