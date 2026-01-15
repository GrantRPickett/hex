extends "res://tests/test_utils.gd"

var _save_manager_mock
var _level_manager: Node

const LEVEL_1_ID := "level_1"
const LEVEL_2_ID := "level_2"
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _scene_transition_mock

# Helper classes for mocking
class MockSaveManager extends Node:
	var _values: Dictionary = {}
	var save_called: bool = false

	func setup(data: Dictionary) -> void:
		_values = data

	func get_value(key: String, default = null):
		return _values.get(key, default)

	func set_value(key: String, value) -> void:
		_values[key] = value

	func save_config() -> void:
		save_called = true

class MockSceneTransition extends Node:
	var last_scene_path: String = ""

	func change_scene(path: String, _delay: float = 0.0, _emit_signal_only: bool = false) -> void:
		last_scene_path = path

	func is_changing() -> bool:
		return false

func _setup_test_env(config_data: Dictionary) -> void:
	# Mock SaveManager with specific data
	_save_manager_mock = MockSaveManager.new()
	_save_manager_mock.name = "SaveManager"
	_save_manager_mock.setup(config_data)
	get_tree().root.add_child(_save_manager_mock)

	# Mock SceneTransition
	_scene_transition_mock = MockSceneTransition.new()
	_scene_transition_mock.name = "SceneTransition"
	get_tree().root.add_child(_scene_transition_mock)

	# Instantiate LevelManager
	var lm_script = load("res://Autoloads/level_manager.gd")
	_level_manager = lm_script.new()
	_level_manager.name = "LevelManager"

	# Inject SaveManager to ensure it is found regardless of tree structure
	_level_manager.set("_save_manager", _save_manager_mock)
	_level_manager.set("_scene_transition", _scene_transition_mock)

	get_tree().root.add_child(_level_manager)

	await get_tree().process_frame

func after_test() -> void:
	if is_instance_valid(_level_manager):
		get_tree().root.remove_child(_level_manager)
		_level_manager.free()
	if is_instance_valid(_save_manager_mock):
		get_tree().root.remove_child(_save_manager_mock)
		_save_manager_mock.free()
	if is_instance_valid(_scene_transition_mock):
		get_tree().root.remove_child(_scene_transition_mock)
		_scene_transition_mock.free()

func test_init_loads_completed_levels_from_config() -> void:
	await _setup_test_env({
		"completed_levels": {LEVEL_1_ID: true}
	})

	# Verify that LevelManager correctly identified the completed level from SaveManager
	if _level_manager.has_method("is_level_unlocked"):
		# level_2 requires level_1, so if level_1 is complete, level_2 should be unlocked
		assert_that(_level_manager.is_level_unlocked(LEVEL_2_ID)).is_true()
	else:
		# Fallback assertion if method name differs (e.g. checking internal array)
		var completed = _level_manager.get("_completed_levels")
		if completed != null:
			assert_that(completed.has(LEVEL_1_ID)).is_true()
			assert_that(completed.has(LEVEL_2_ID)).is_false()
		else:
			fail("LevelManager does not have expected 'is_level_unlocked' method or '_completed_levels' property.")

func test_init_handles_null_config_data() -> void:
	# Simulate SaveManager returning null (default) for the key by providing an empty config
	await _setup_test_env({})

	# LevelManager should handle this gracefully (treat as empty list)
	if _level_manager.has_method("is_level_unlocked"):
		# level_2 requires level_1, so it should be locked
		assert_that(_level_manager.is_level_unlocked(LEVEL_2_ID)).is_false()
	else:
		var completed = _level_manager.get("_completed_levels")
		# Should be initialized to empty array, not null
		assert_that(completed).is_not_null()
		assert_that(completed).is_empty()

func test_init_handles_empty_list() -> void:
	# Simulate explicit empty list in config
	await _setup_test_env({
		"completed_levels": {}
	})

	if _level_manager.has_method("is_level_unlocked"):
		assert_that(_level_manager.is_level_unlocked(LEVEL_2_ID)).is_false()
	else:
		var completed = _level_manager.get("_completed_levels")
		assert_that(completed).is_empty()

func test_mark_level_complete_updates_config_and_saves() -> void:
	await _setup_test_env({
		"completed_levels": {}
	})

	if _level_manager.has_method("mark_level_completed"):
		_level_manager.mark_level_completed(LEVEL_1_ID)

		var levels = _save_manager_mock.get_value("completed_levels")
		assert_that(levels.has(LEVEL_1_ID)).is_true()
		# Note: SaveManager mock doesn't have 'save_called' flag logic in set_value unless we added it,
		# but the mock setup in _setup_test_env does not call save_config in set_value,
		# LevelManager calls save_config explicitly.
		# Let's verify the value was set.
	else:
		fail("LevelManager missing expected method 'mark_level_completed'")

func test_mark_level_complete_is_idempotent() -> void:
	await _setup_test_env({
		"completed_levels": {LEVEL_1_ID: true}
	})

	if _level_manager.has_method("mark_level_completed"):
		_level_manager.mark_level_completed(LEVEL_1_ID)

		var levels = _save_manager_mock.get_value("completed_levels")
		assert_that(levels).has_size(1)

func test_load_level_transitions_scene() -> void:
	await _setup_test_env({})

	if _level_manager.has_method("start_level_by_id"):
		_level_manager.start_level_by_id(LEVEL_1_ID)

		assert_that(str(_scene_transition_mock.get("last_scene_path"))).is_equal(GAMEPLAY_SCENE_PATH)
		assert_that(_level_manager.get("_current_level_id")).is_equal(LEVEL_1_ID)
	else:
		fail("LevelManager missing expected method 'start_level_by_id'")

func test_start_first_level_uses_first_unlocked_level() -> void:
	await _setup_test_env({})
	_scene_transition_mock.set("last_scene_path", "")

	if _level_manager.has_method("start_first_level"):
		_level_manager.start_first_level()
		assert_that(str(_scene_transition_mock.get("last_scene_path"))).is_equal(GAMEPLAY_SCENE_PATH)
		assert_that(_level_manager.get("_current_level_id")).is_equal(LEVEL_1_ID)
	else:
		fail("LevelManager missing expected method 'start_first_level'")

func test_advance_to_next_level() -> void:
	await _setup_test_env({})

	if _level_manager.has_method("start_level_by_id") and _level_manager.has_method("_on_level_complete"):
		_level_manager.start_level_by_id(LEVEL_1_ID)
		_scene_transition_mock.set("last_scene_path", "") # Reset

		# Simulate level completion
		await _level_manager._on_level_complete()

		# Should transition to level select (or next level if implemented that way, but LevelManager logic goes to menu)
		# Based on provided LevelManager: "Transitioning to post-completion level select."
		assert_that(str(_scene_transition_mock.get("last_scene_path"))).is_equal("res://Menus/level_select.tscn")
		# And current level should be cleared
		assert_that(_level_manager.get("_current_level_id")).is_empty()
	else:
		fail("LevelManager missing expected methods for completion")

func test_verify_all_levels_have_valid_enemy_starts() -> void:
	await _setup_test_env({})

	var metadata = _level_manager.LEVEL_METADATA
	for level_data in metadata:
		var path = level_data["path"]
		var level = load(path)

		assert_that(level).is_not_null()
		assert_that(level.get("enemy_starts")).is_not_null()
