extends GdUnitTestSuite

const LevelCatalogClass = preload("res://level/level_catalog.gd")

func test_get_level_by_id() -> void:
	var catalog = auto_free(LevelCatalogClass.new())
	var level = catalog.get_level_by_id("hometown")
	assert_str(level.get("id")).is_equal("hometown")
	assert_str(level.get("path")).is_equal("res://Resources/level_data/hometown/hometown.tres")

	var missing = catalog.get_level_by_id("nonexistent")
	assert_bool(missing.is_empty()).is_true()

func test_find_level_by_path() -> void:
	var catalog = auto_free(LevelCatalogClass.new())
	var level = catalog.find_level_by_path("res://Resources/level_data/hometown/hometown.tres")
	assert_str(level.get("id")).is_equal("hometown")

	var missing = catalog.find_level_by_path("invalid/path")
	assert_bool(missing.is_empty()).is_true()
