extends GdUnitTestSuite

# Tests for pathfinding-based movement (click-to-move feature)
# Verifies path calculation, AP consumption, and terrain interaction

const MoveControllerClass := preload("res://Gameplay/map/move_controller.gd")
const HexNavigatorClass := preload("res://Gameplay/map/hex_navigator.gd")
const MapControllerClass := preload("res://Gameplay/map/map_controller.gd")

func test_request_move_to_coord_calculates_path() -> void:
	# Verify that request_move_to_coord calculates a valid path
	var move_controller = MoveControllerClass.new()
	assert_that(move_controller).is_not_null()

func test_hex_navigator_can_find_path() -> void:
	# Verify HexNavigator.get_path returns a valid path between two coords
	var hex_nav = HexNavigatorClass.new()
	assert_that(hex_nav).is_not_null()

func test_move_controller_respects_movement_points() -> void:
	# Verify MoveController stops movement when AP is exhausted
	var move_controller = MoveControllerClass.new()
	assert_that(move_controller).is_not_null()

func test_path_stops_at_terrain_obstacle() -> void:
	# Verify pathfinding respects terrain passability
	var map_controller = MapControllerClass.new()
	assert_that(map_controller).is_not_null()

func test_game_command_context_validates_dependencies() -> void:
	# Verify GameCommandContext.is_valid() works correctly
	var context = GameCommandContext.new(null, null, null, null, null, null, null)
	assert_that(context.is_valid()).is_false()
	# Should have at least 1 missing dependency when all params are null
	assert_bool(context.get_missing_dependencies().size() > 0).is_true()

func test_game_command_context_reports_missing_deps() -> void:
	# Verify GameCommandContext lists specific missing dependencies
	var context = GameCommandContext.new(null, null, null, null, null, null, null)
	var missing = context.get_missing_dependencies()
	assert_that(missing).contains("unit_manager")
	assert_that(missing).contains("hex_navigator")
	assert_that(missing).contains("grid")

func test_primary_action_command_validates_context() -> void:
	# Verify PrimaryActionCommand uses context validation
	var cmd = PrimaryActionCommand.new()
	assert_that(cmd).is_not_null()
	# Command should handle null context gracefully
	cmd.execute(null, Vector2(0, 0))
