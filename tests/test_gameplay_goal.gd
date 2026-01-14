extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

class UnitTestLevel extends Resource:
	var player_starts: Array[Vector2i] = []
	var goal_coords: Array[Vector2i] = []
	var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var require_all_units: bool = false
	var initial_rotation: float = 0.0
	var grid_width: int = 7
	var grid_height: int = 7

var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await setup_autoloads({
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(2, 2)] as Array[Vector2i]
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	# Manually place the player at the goal to trigger completion
	scene.set_player_coord(scene.goal_coord)
	scene.update_goal_progress_for_selected()
	await runner.simulate_frames(1)

	# Verify goal is marked as reached
	assert_bool(scene._goal_reached).is_true()

	var coord_at_goal = scene.player_coord

	# Attempt to move after goal is reached
	scene.request_move("move_s")
	await runner.simulate_frames(1)

	# Assert that the player's coordinate has not changed
	assert_vector(scene.player_coord).is_equal(coord_at_goal)