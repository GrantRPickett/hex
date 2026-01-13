extends "res://tests/test_utils.gd"

var _level_manager: Node = null
var _save_manager: Node = null
var _control_settings: Node = null
var _input_mapper: Node = null
const AUTOLOADS = {
	"SaveManager": "res://Autoloads/save_manager.gd",
	"LevelManager": "res://Autoloads/level_manager.gd",
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	_save_manager = await ensure_manager("SaveManager", "res://Autoloads/save_manager.gd")
	_level_manager = await ensure_manager("LevelManager", "res://Autoloads/level_manager.gd")
	var dir = DirAccess.open("user://")
	if dir.file_exists("save_game.cfg"):
		dir.remove("save_game.cfg")
	_control_settings = await ensure_manager("ControlSettings", "res://Autoloads/control_settings.gd")
	_input_mapper = await ensure_manager("InputMapper", "res://Autoloads/input_mapper.gd")

func after_test() -> void:
	await teardown_autoloads()


func test_start_level_by_id_sets_current_level() -> void:
	# Note: LevelManager uses a hardcoded LEVEL_METADATA list.
	# We can't dynamically set levels for this test.

	# Test starting a known level by ID
	_level_manager.start_level_by_id("level2")
	assert_that(_level_manager._current_level_id).is_equal("level2")
	assert_that(_level_manager._current_level_path).is_equal("res://Resources/levels/level2.tres")

	# Test starting a different known level by ID
	_level_manager.start_level_by_id("level1")
	assert_that(_level_manager._current_level_id).is_equal("level1")
	assert_that(_level_manager._current_level_path).is_equal("res://Resources/levels/level1.tres")

	# Test starting an unknown level ID is currently disabled because
	# the testing framework does not support asserting for `push_error` easily.
	pass
