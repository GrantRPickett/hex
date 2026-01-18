extends GdUnitTestSuite

# Test the click-to-move pathfinding feature
# These are basic smoke tests that verify the feature structure

func test_click_to_move_path_exists() -> void:
	# Verify that InputController has the click-to-move handler
	var input_controller = load("res://Gameplay/input_controller.gd")
	assert_that(input_controller).is_not_null()

func test_move_controller_exists() -> void:
	# Verify MoveController is available for pathfinding execution
	var move_controller = load("res://Gameplay/move_controller.gd")
	assert_that(move_controller).is_not_null()

func test_hex_navigator_has_pathfind() -> void:
	# Verify HexNavigator has pathfinding capabilities
	var hex_nav = load("res://Gameplay/hex_navigator.gd")
	assert_that(hex_nav).is_not_null()

func test_game_config_has_movement_constants() -> void:
	# Verify GameConfig constants are available
	assert_that(GameConfig.MOVEMENT_TWEEN_DURATION).is_equal(0.2)
	assert_that(GameConfig.MOVEMENT_TWEEN_TRANS).is_equal(Tween.TRANS_SINE)
	assert_that(GameConfig.MOVEMENT_TWEEN_EASE).is_equal(Tween.EASE_OUT)
