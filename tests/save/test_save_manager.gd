extends "res://tests/test_utils.gd"

var _save_manager: Node

func before_test() -> void:
	# Clean up save file before starting
	var dir = DirAccess.open("user://")
	if dir.file_exists("save_game.cfg"):
		dir.remove("save_game.cfg")

	_save_manager = await ensure_manager("SaveManager", "res://Autoloads/save_manager.gd")

func after_test() -> void:
	if is_instance_valid(_save_manager):
		_save_manager.queue_free()
	await get_tree().process_frame

func test_set_and_get_value() -> void:
	_save_manager.set_value("test_string", "hello")
	assert_eq(_save_manager.get_value("test_string"), "hello")

	_save_manager.set_value("test_int", 123)
	assert_eq(_save_manager.get_value("test_int"), 123)

	var dict = {"key": "value"}
	_save_manager.set_value("test_dict", dict)
	assert_eq(_save_manager.get_value("test_dict"), dict)

func test_get_value_defaults() -> void:
	assert_that(_save_manager.get_value("non_existent")).is_null()
	assert_eq(_save_manager.get_value("non_existent", "default"), "default")

func test_persistence() -> void:
	_save_manager.set_value("persisted_key", "saved")

	# Simulate game restart by freeing and reloading the manager
	_save_manager.queue_free()
	await get_tree().process_frame

	_save_manager = await ensure_manager("SaveManager", "res://Autoloads/save_manager.gd")

	assert_eq(_save_manager.get_value("persisted_key"), "saved")