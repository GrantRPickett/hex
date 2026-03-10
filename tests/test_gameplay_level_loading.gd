extends GdUnitTestSuite
const HexTestUtils = preload("res://tests/base_test_suite.gd")
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/level_data/levels/level_1.tres"
const LEVEL2_PATH := "res://Resources/level_data/levels/level_2.tres"

var _level_manager: Node
var _save_manager: Node
var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await HexTestUtils.setup_autoloads(get_tree(), {
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
	await HexTestUtils.teardown_autoloads(get_tree())
