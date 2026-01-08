extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

func test_goal_reached_prevents_double_scene_change() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene.set_player_coord(Vector2i(0, 0))
	scene.set_goal_coord(Vector2i(1, 0))
	scene.request_move("move_d")
	# call again before the deferred change executes
	scene.request_move("move_d")
	await runner.simulate_until_object_signal(scene.get_tree(), "scene_changed")

	var current := scene.get_tree().current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(CREDITS_SCENE_PATH)

func test_request_move_ignores_invalid_action() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene.set_player_coord(Vector2i(2, 2))
	scene.request_move("not_an_action")
	await runner.simulate_frames(1)

	assert_that(scene.player_coord).is_equal(Vector2i(2, 2))


func test_request_move_stops_at_bounds() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene.set_player_coord(Vector2i(0, 0))
	scene.request_move("move_q")
	await runner.simulate_frames(1)

	assert_that(scene.player_coord).is_equal(Vector2i(0, 0))


func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene.set_player_coord(Vector2i(0, 0))
	scene.set_goal_coord(Vector2i(1, 0))
	scene.request_move("move_d")
	assert_that(scene.player_coord).is_equal(Vector2i(1, 0))

	scene.request_move("move_s")
	await runner.simulate_frames(1)

	assert_that(scene.player_coord).is_equal(Vector2i(1, 0))
