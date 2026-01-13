extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _control_settings: Node
var _input_mapper: Node

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await _simulate_frames(runner, 1)

	# Manually place the player at the goal to trigger completion
	scene.set_player_coord(scene.goal_coord)
	scene.update_goal_progress_for_selected()
	await _simulate_frames(runner, 1)

	# Verify goal is marked as reached
	assert_that(scene._goal_reached).is_true()

	var coord_at_goal = scene.player_coord

	# Attempt to move after goal is reached
	scene.request_move("move_s")
	await _simulate_frames(runner, 1)

	# Assert that the player's coordinate has not changed
	assert_that(scene.player_coord).is_equal(coord_at_goal)