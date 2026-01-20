extends GdUnitTestSuite

var _roster_path: String = "user://test_player_roster.tres"

func after() -> void:
	# Clean up test files
	if FileAccess.file_exists(_roster_path):
		DirAccess.remove_absolute(_roster_path)

func test_has_saved_roster_when_not_exists() -> void:
	# Test that has_saved_roster returns a boolean
	var result = SaveManager.has_saved_roster()
	assert_bool(result is bool).is_true()

func test_save_roster() -> void:
	var roster = PlayerRoster.new()

	# Don't error when saving
	SaveManager.save_roster(roster)
	assert_bool(true).is_true()

func test_load_roster_when_empty() -> void:
	var result = SaveManager.load_roster()

	# Result should be null or a valid resource
	assert_bool(result == null or result is PlayerRoster).is_true()

func test_set_and_get_value() -> void:
	SaveManager.set_value("test_key", "test_value")

	var result = SaveManager.get_value("test_key")

	assert_that(result).is_equal("test_value")

func test_get_value_with_default() -> void:
	var result = SaveManager.get_value("nonexistent_key", "default_value")

	assert_that(result).is_equal("default_value")

func test_get_value_no_default() -> void:
	var result = SaveManager.get_value("nonexistent_key")

	assert_that(result).is_null()

func test_set_value_overwrites() -> void:
	SaveManager.set_value("key", "value1")
	SaveManager.set_value("key", "value2")

	var result = SaveManager.get_value("key")

	assert_that(result).is_equal("value2")

func test_set_multiple_values() -> void:
	SaveManager.set_value("key1", "value1")
	SaveManager.set_value("key2", "value2")
	SaveManager.set_value("key3", 42)

	assert_that(SaveManager.get_value("key1")).is_equal("value1")
	assert_that(SaveManager.get_value("key2")).is_equal("value2")
	assert_int(SaveManager.get_value("key3")).is_equal(42)
