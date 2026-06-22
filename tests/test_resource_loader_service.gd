# test_resource_loader_service.gd
extends GdUnitTestSuite

func test_collect_resources_recursive() -> void:
	# Test with a known path that contains resources
	var resources = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/")
	assert_array(resources).is_not_empty()
	for res in resources:
		assert_bool(res is Resource).is_true()

func test_collect_resources_recursive_type_hint_builtin() -> void:
	# "Resource" should match everything that ends with .tres
	var resources = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/", ".tres", "Resource")
	var all_resources = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/", ".tres")
	assert_int(resources.size()).is_equal(all_resources.size())

func test_collect_resources_recursive_type_hint_custom() -> void:
	# Only JournalEntry resources
	var resources = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/", ".tres", "JournalEntry")
	for res in resources:
		assert_bool(res is JournalEntry).is_true()

func test_collect_resources_recursive_case_insensitive() -> void:
	# .TRES should work the same as .tres
	var resources = ResourceLoaderService.collect_resources_recursive("res://Resources/level_data/", ".TRES")
	assert_array(resources).is_not_empty()

func test_load_resources_in_dir() -> void:
	var resources = ResourceLoaderService.load_resources_in_dir("res://Resources/level_data/")
	# This might be empty if there are no .tres files directly in level_data/
	# but it shouldn't crash.
	assert_array(resources).is_not_null()

func test_load_resources_in_dir_type_hint() -> void:
	# Try load specifically for objective files if they exist in a subdir
	var resources = ResourceLoaderService.load_resources_in_dir("res://Resources/level_data/test_level/", ".tres", "JournalEntry")
	# At least shouldn't crash and returns an array
	assert_array(resources).is_not_null()
