extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

func test_request_move_ignores_invalid_action() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	scene.set_player_coord(Vector2i(2, 2))
	scene.request_move("not_an_action")
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	assert_that(scene.player_coord).is_equal(Vector2i(2, 2))


func test_request_move_stops_at_bounds() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	scene.set_player_coord(Vector2i(0, 0))
	scene.request_move("move_q")
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	assert_that(scene.player_coord).is_equal(Vector2i(0, 0))


func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	scene.set_player_coord(Vector2i(0, 0))
	scene.set_goal_coord(Vector2i(1, 0))

	# The signal is emitted synchronously during request_move
	scene.request_move("move_d")
	assert_that(scene.player_coord).is_equal(Vector2i(1, 0))

	# Now that goal is reached, attempt move after - should be ignored
	scene.request_move("move_s")
	@warning_ignore("redundant_await")
	_simulate_frames(runner, 1)

	assert_that(scene.player_coord).is_equal(Vector2i(1, 0))
