extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level1.tres"
const LEVEL2_PATH := "res://Resources/levels/level2.tres"

var _level_manager: Node
var _save_manager: Node
var _control_settings: Node
var _input_mapper: Node

const AUTOLOADS = {
	"SaveManager": "res://Autoloads/save_manager.gd",
	"LevelManager": "res://Autoloads/level_manager.gd",
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_save_manager = instances["SaveManager"]
	_level_manager = instances["LevelManager"]
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	# LevelManager state reset is handled by queue_free in teardown
	await teardown_autoloads()


func test_gameplay_applies_level_manager_selection() -> void:
	# Manually set the current level in LevelManager
	_level_manager._current_level_id = "level2"
	_level_manager._current_level_path = LEVEL2_PATH

	var runner := _create_scene_runner(GAMEPLAY_SCENE)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var level := load(LEVEL2_PATH)

	assert_that(scene.level_resource).is_not_null()
	assert_that(scene.player_coord).is_equal(level.player_starts[0])
	assert_that(scene.goal_coord).is_equal(level.goal_coords[0])
	assert_that(scene.goal2_coord).is_equal(level.goal_coords[1])
	assert_that(scene._grid_width).is_equal(level.grid_width)

	assert_that(scene._grid.tile_set.tile_offset_axis).is_equal(level.hex_offset_axis)
