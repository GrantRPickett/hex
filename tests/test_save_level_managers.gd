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
	"InputMapper": "res://Autoloads/input_mapper.gd",

}

func before_test() -> void:
	# Clear any previous save data before each test to ensure isolation
	super._clear_save_game()
	var instances = await setup_autoloads(AUTOLOADS_TO_MANAGE)
	_save_manager_instance = instances["SaveManager"]
	_level_manager_instance = instances["LevelManager"]
	_control_settings = instances["ControlSettings"]

	# Reset internal state to prevent test pollution if autoloads are reused
	_save_manager_instance.set_value("completed_levels", {})
	if _level_manager_instance.has_method("reset_completed_levels"):
		_level_manager_instance.reset_completed_levels()

	# Inject the test SaveManager instance into LevelManager to ensure it uses the isolated instance
	# instead of the global singleton (which might be different or missing in the test environment).
	_level_manager_instance.set("save_manager", _save_manager_instance)
	_level_manager_instance.set("_save_manager", _save_manager_instance)

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
	var test_completed_levels = {"level_1": true, "level_2": true, "level_3": true}

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
	assert_that(_level_manager_instance.get_level_info("level_1")).is_not_empty()
	assert_that(_level_manager_instance.get_level_info("non_existent_level")).is_empty()


func test_level_manager_level1_is_unlocked_by_default() -> void:
	# Given initial state (level1 is unlocked by default)
	# Then level1 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level_1")).is_true()


func test_level_manager_prerequisites_unlock_levels() -> void:
	# Given level1 is completed (by default or from save)
	_level_manager_instance.mark_level_completed("level_1")
	# Then level2, level3, level4 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level_2")).is_true()
	assert_that(_level_manager_instance.is_level_unlocked("level_3")).is_true()
	assert_that(_level_manager_instance.is_level_unlocked("level_4")).is_true()
	# Given level2 and level3 are NOT completed yet
	# Then level5 should NOT be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level_5")).is_false()

	# When level2 and level3 are completed
	_level_manager_instance.mark_level_completed("level_2")
	_level_manager_instance.mark_level_completed("level_3")
	# Then level5 should be unlocked
	assert_that(_level_manager_instance.is_level_unlocked("level_5")).is_true()


func test_level_manager_mark_level_completed_updates_and_saves() -> void:
	# Given an unlocked level that is not completed
	assert_bool(_level_manager_instance.is_level_completed("level_1")).is_false()

	# When it is marked completed
	_level_manager_instance.mark_level_completed("level_1")

	# Then completion state should update
	assert_bool(_level_manager_instance.is_level_completed("level_1")).is_true()

	# And save data should reflect this
	var loaded_levels = _save_manager_instance.get_value("completed_levels")
	assert_that(loaded_levels.has("level_1")).is_true()

func test_level_manager_get_available_levels() -> void:
	# Given initial state (level1 completed)
	_level_manager_instance.mark_level_completed("level_1")
	var available = _level_manager_instance.get_available_levels()
	# Expect level1, level2, level3, level4 to be available and have display names
	assert_that(available.map(func(l): return l["id"])).contains_exactly_in_any_order(["level_1", "level_2", "level_3", "level_4"])
	assert_that(available.filter(func(l): return l["id"] == "level_1")[0]["display_name"]).is_equal("The Beginning")
	# When level2 and level3 are completed
	_level_manager_instance.mark_level_completed("level_2")
	_level_manager_instance.mark_level_completed("level_3")

	# Then level5 should also be available, and level1,2,3,4 still available
	available = _level_manager_instance.get_available_levels()
	assert_that(available.map(func(l): return l["id"])).contains_exactly_in_any_order(["level_1", "level_2", "level_3", "level_4", "level_5"])
	assert_that(available.filter(func(l): return l["id"] == "level_5")[0]["display_name"]).is_equal("Twin Peaks")


func test_level_manager_start_level_by_id() -> void:
	# Given LevelManager is initialized
	# When start_level_by_id is called
	_level_manager_instance.start_level_by_id("level_1")

	# Then current level id should be "level_1" and path should be correct
	assert_that(_level_manager_instance.get_current_level_id()).is_equal("level_1")
	assert_that(_level_manager_instance.get_current_level_path()).is_equal("res://Resources/levels/level_1.tres")
	# Assert that scene change is requested (difficult to test directly without mocking SceneTransition)
	# For now, rely on integration with SceneTransition if it's mocked or actual tests are run.

func test_level_manager_on_level_complete_transitions_to_credits_when_no_more_unlocked() -> void:
	# Given all levels are completed up to level 7
	_level_manager_instance.mark_level_completed("level_1")
	_level_manager_instance.mark_level_completed("level_2")
	_level_manager_instance.mark_level_completed("level_3")
	_level_manager_instance.mark_level_completed("level_4")
	_level_manager_instance.mark_level_completed("level_5")
	_level_manager_instance.mark_level_completed("level_6")
	_level_manager_instance.mark_level_completed("level_7")
	_level_manager_instance.start_level_by_id("level_7")

	# When _on_level_complete is called
	_level_manager_instance._on_level_complete()

	# Then it should transition to credits (difficult to mock SceneTransition for direct assert)
	# But current level should be reset
	assert_that(_level_manager_instance.get_current_level_id()).is_empty()
	assert_that(_level_manager_instance.get_current_level_path()).is_empty()
