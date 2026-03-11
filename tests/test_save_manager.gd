extends GdUnitTestSuite

func before_test() -> void:
	# Clear save data before each test
	SaveManager._game_data = {}

func test_set_and_get_value() -> void:
	SaveManager.set_value("test_key", "test_value")
	var result = SaveManager.get_value("test_key")
	assert_that(result).is_equal("test_value")

func test_get_value_returns_default() -> void:
	var result = SaveManager.get_value("non_existent_key", "default")
	assert_that(result).is_equal("default")

func test_overwrite_value() -> void:
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

func test_set_global_flag() -> void:
	SaveManager.set_global_flag("has_met_king", true)
	var flags = SaveManager.get_global_flags()
	assert_that(flags.has("has_met_king")).is_true()
	assert_that(flags["has_met_king"]).is_true()

func test_set_level_flag() -> void:
	SaveManager.set_level_flag("level_1", "chest_opened", true)
	var flags = SaveManager.get_level_flags("level_1")
	assert_that(flags.has("chest_opened")).is_true()
	assert_that(flags["chest_opened"]).is_true()
