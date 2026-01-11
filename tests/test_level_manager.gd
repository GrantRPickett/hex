extends GdUnitTestSuite

var _original_levels: Array = []
var _original_index: int = -1
var _original_path := ""

func before_test() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	_original_levels = LevelManager.levels.duplicate(true)
	_original_index = LevelManager.current_index
	_original_path = LevelManager.get_current_level_path()

func after_test() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	LevelManager.set_levels(_original_levels)
	LevelManager.set_current_level_path(_original_path)
	LevelManager.current_index = _original_index

func test_level_manager_api() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	LevelManager.set_levels(["res://Resources/levels/level1.tres", "res://Resources/levels/level2.tres"])
	LevelManager.set_current_level_path("res://Resources/levels/level1.tres")
	var path: String = LevelManager.get_current_level_path()
	assert_that(path).is_equal("res://Resources/levels/level1.tres")

func test_set_levels_duplicates_input_array() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	var original := ["res://Resources/levels/level1.tres", "res://Resources/levels/level2.tres"]
	LevelManager.set_levels(original)
	original[0] = "res://mutated.tres"
	assert_that(LevelManager.levels[0]).is_equal("res://Resources/levels/level1.tres")

func test_set_current_level_path_updates_index() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	var order := [
		"res://Resources/levels/level1.tres",
		"res://Resources/levels/level2.tres",
	]
	LevelManager.set_levels(order)
	LevelManager.set_current_level_path(order[1])
	assert_that(LevelManager.current_index).is_equal(1)
	assert_that(LevelManager.get_current_level_path()).is_equal(order[1])

func test_set_current_level_path_tracks_unknown_entries() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	LevelManager.set_levels(["res://Resources/levels/level1.tres"])
	var custom := "res://custom_level.tres"
	LevelManager.set_current_level_path(custom)
	assert_that(LevelManager.get_current_level_path()).is_equal(custom)
	assert_that(LevelManager.current_index).is_equal(-1)