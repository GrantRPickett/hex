extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level_1.tres"
const LEVEL2_PATH := "res://Resources/levels/level_2.tres"

var _level_manager: Node
var _save_manager: Node
var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await setup_autoloads({
		"SaveManager": "res://Autoloads/save_manager.gd",
		"LevelManager": "res://Autoloads/level_manager.gd",
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_save_manager = instances["SaveManager"]
	_level_manager = instances["LevelManager"]
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func test_gameplay_applies_level_manager_selection() -> void:
	_level_manager.set_current_level(LEVEL1_PATH)
	await get_tree().process_frame	
	var runner := scene_runner(GAMEPLAY_SCENE)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var level := load(LEVEL2_PATH)

	assert_object(scene.level_resource).is_not_null()
	assert_vector(scene.player_coord).is_equal(level.player_starts[0])
	assert_vector(scene.goal_coord).is_equal(level.goal_coords[0])
	assert_vector(scene.goal2_coord).is_equal(level.goal_coords[1])
	assert_int(scene._grid_width).is_equal(level.grid_width)

	assert_int(scene._grid.tile_set.tile_offset_axis).is_equal(level.hex_offset_axis)
