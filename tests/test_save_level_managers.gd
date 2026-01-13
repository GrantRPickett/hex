extends "res://tests/test_utils.gd"

# Test cases for LevelManager and SaveManager
var _level_manager_instance: Node
var _save_manager_instance: Node
var _control_settings: Node

# Define autoloads needed for this test suite.
# The dictionary preserves insertion order, which is important here since
# LevelManager depends on SaveManager.
const AUTOLOADS_TO_MANAGE = {
	"SaveManager": "res://Autoloads/save_manager.gd",
	"LevelManager": "res://Autoloads/level_manager.gd",
	"ControlSettings": "res://Autoloads/control_settings.gd",
}

func before_test() -> void:
	# Clear any previous save data before each test to ensure isolation
	super._clear_save_game()
	var instances = await setup_autoloads(AUTOLOADS_TO_MANAGE)
	_save_manager_instance = instances["SaveManager"]
	_level_manager_instance = instances["LevelManager"]
	_control_settings = instances["ControlSettings"]


func after_test() -> void:
	await teardown_autoloads()


func test_save_manager_initially_has_no_completed_levels() -> void:
	# Given no save file exists initially (cleared in before_test)
	# When SaveManager is queried for completed levels
	var completed = _save_manager_instance.get_value("completed_levels", {})
	# Then it should be empty. Level 1 is unlocked via LevelManager metadata logic, not save data.
	assert_that(completed.is_empty()).is_true()


func test_save_manager_saves_and_loads_completed_levels() -> void:
	# Given some completed levels
	var test_completed_levels = {"level1": true, "level2": true, "level3": true}

	# When they are saved
	_save_manager_instance.set_value("completed_levels", test_completed_levels)

	# Then they should be loaded back correctly
	var loaded_levels = _save_manager_instance.get_value("completed_levels")
	assert_that(loaded_levels.size()).is_equal(test_completed_levels.size())
	for key in test_completed_levels:
		assert_that(loaded_levels.has(key)).is_true()
		assert_that(loaded_levels[key]).is_equal(test_completed_levels[key])


func test_level_manager_initializes_with_level_data() -> void:
	# Given LevelManager is ready
	# Then _level_data should be populated
	assert_that(_level_manager_instance._level_data).is_not_empty()
	assert_that(_level_manager_instance._level_data.size()).is_equal(7)
	assert_that(_level_manager_instance.get_level_info("level1")).is_not_empty()
	assert_that(_level_manager_instance.get_level_info("non_existent_level")).is_empty()


func test_level_manager_level1_is_unlocked_by_default() -> void:
	# Given initial state (level1 is marked completed by SaveManager if no save exists)
	# Then level1 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level1")).is_true()


func test_level_manager_prerequisites_unlock_levels() -> void:
	# Given level1 is completed (by default or from save)
	_level_manager_instance.mark_level_completed("level1")
	# Then level2, level3, level4 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level2")).is_true()
	assert_that(_level_manager_instance.is_level_unlocked("level3")).is_true()
	assert_that(_level_manager_instance.is_level_unlocked("level4")).is_true()

	# Given level2 and level3 are NOT completed yet
	# Then level5 should NOT be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level5")).is_false()

	# When level2 and level3 are completed
	_level_manager_instance.mark_level_completed("level2")
	_level_manager_instance.mark_level_completed("level3")

	# Then level5 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level5")).is_true()


func test_level_manager_mark_level_completed_updates_and_saves() -> void:
	# Given an unlocked level that is not completed
	assert_that(_level_manager_instance._completed_levels.has("level2")).is_false()

	# When it is marked completed
	_level_manager_instance.mark_level_completed("level2")

	# Then _completed_levels should be updated
	assert_that(_level_manager_instance._completed_levels.has("level2")).is_true()

	# And save data should reflect this (by reloading SaveManager data)
	var loaded_levels = _save_manager_instance.get_value("completed_levels")
	assert_that(loaded_levels.has("level2")).is_true()


func test_level_manager_get_available_levels() -> void:
	# Given initial state (level1 completed)
	_level_manager_instance.mark_level_completed("level1")
	var available = _level_manager_instance.get_available_levels()
	# Expect level1, level2, level3, level4 to be available and have display names
	assert_that(available.map(func(l): return l.id)).contains_exactly_in_any_order(["level1", "level2", "level3", "level4"])
	assert_that(available.filter(func(l): return l.id == "level1")[0].display_name).is_equal("The Beginning")

	# When level2 and level3 are completed
	_level_manager_instance.mark_level_completed("level2")
	_level_manager_instance.mark_level_completed("level3")

	# Then level5 should also be available, and level1,2,3,4 still available
	available = _level_manager_instance.get_available_levels()
	assert_that(available.map(func(l): return l.id)).contains_exactly_in_any_order(["level1", "level2", "level3", "level4", "level5"])
	assert_that(available.filter(func(l): return l.id == "level5")[0].display_name).is_equal("Twin Peaks")


func test_level_manager_start_level_by_id() -> void:
	# Given LevelManager is initialized
	# When start_level_by_id is called
	_level_manager_instance.start_level_by_id("level1")

	# Then _current_level_id should be "level1" and path should be correct
	assert_that(_level_manager_instance._current_level_id).is_equal("level1")
	assert_that(_level_manager_instance._current_level_path).is_equal("res://Resources/levels/level1.tres")
	# Assert that scene change is requested (difficult to test directly without mocking SceneTransition)
	# For now, rely on integration with SceneTransition if it's mocked or actual tests are run.

func test_level_manager_on_level_complete_transitions_to_credits_when_no_more_unlocked() -> void:
	# Given all levels are completed up to level 7
	_level_manager_instance.mark_level_completed("level1")
	_level_manager_instance.mark_level_completed("level2")
	_level_manager_instance.mark_level_completed("level3")
	_level_manager_instance.mark_level_completed("level4")
	_level_manager_instance.mark_level_completed("level5")
	_level_manager_instance.mark_level_completed("level6")
	_level_manager_instance.mark_level_completed("level7")

	_level_manager_instance._current_level_id = "level7" # Set current to last level

	# When _on_level_complete is called
	_level_manager_instance._on_level_complete()

	# Then it should transition to credits (difficult to mock SceneTransition for direct assert)
	# But _current_level_id should be reset
	assert_that(_level_manager_instance._current_level_id).is_empty()

	assert_that(_level_manager_instance._current_level_path).is_empty()
