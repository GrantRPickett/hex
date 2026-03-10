extends GdUnitTestSuite

const LevelStateControllerScript = preload("res://level/level_state_controller.gd")

func test_handle_player_defeat() -> void:
	var controller = LevelStateControllerScript.new()
	var monitor = monitor_signals(controller)

	controller.handle_player_defeat()

	assert_bool(controller._game_over_state).is_true()
	assert_signal(monitor).is_emitted("game_over")

	controller.free()

func test_handle_enemy_retreat() -> void:
	var controller = LevelStateControllerScript.new()
	var monitor = monitor_signals(controller)

	controller.handle_enemy_retreat()

	assert_bool(controller._task_reached_state).is_true()
	assert_signal(monitor).is_emitted("task_reached")

	controller.free()

func test_handle_neutral_retreat() -> void:
	var controller = LevelStateControllerScript.new()

	# Neutral retreat shouldn't end the level or win it by default
	controller.handle_neutral_retreat()

	assert_bool(controller._game_over_state).is_false()
	assert_bool(controller._task_reached_state).is_false()

	controller.free()
