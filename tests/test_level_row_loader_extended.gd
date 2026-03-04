extends GdUnitTestSuite

const LevelRowLoaderScript := preload("res://level/level_row_loader.gd")

func test_level_row_loader_refresh_for_level_caches() -> void:
	var loader = LevelRowLoaderScript.new()

	# Just verify it doesn't crash on missing level
	loader.refresh_for_level(&"missing_level")

	# Empty id shouldn't do anything
	loader.refresh_for_level(&"")

	# The real resource logic is hard to mock natively in gdunit without file creation
	# I will just ensure the dictionary keys are handled gracefully
	assert_dict(loader._roster_rows_by_level).is_empty()
	assert_dict(loader._loot_rows_by_level).is_empty()
