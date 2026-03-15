extends GdUnitTestSuite

# Tests for FilePathsLoader — pure RefCounted.
# We bypass the file-load step by directly injecting _paths_dict,
# which lets us test all query methods without touching the filesystem.

const LoaderScript := preload("res://Resources/file_paths_loader.gd")

func _make_loader(injected_dict: Dictionary) -> FilePathsLoader:
	var loader: FilePathsLoader = LoaderScript.new()
	loader._paths_dict = injected_dict
	auto_free(loader)
	return loader

# ---------------------------------------------------------------------------
# get_path — dot-notation key traversal
# ---------------------------------------------------------------------------

func test_get_path_single_level_key() -> void:
	var loader: FilePathsLoader = _make_loader({
		"gameplay": "res://Gameplay/gameplay.tscn"
	})
	assert_str(loader.get_path("gameplay")).is_equal("res://Gameplay/gameplay.tscn")

func test_get_path_two_level_dot_notation() -> void:
	var loader: FilePathsLoader = _make_loader({
		"scenes": {"gameplay": "res://Gameplay/gameplay.tscn"}
	})
	assert_str(loader.get_path("scenes.gameplay")).is_equal("res://Gameplay/gameplay.tscn")

func test_get_path_three_level_dot_notation() -> void:
	var loader: FilePathsLoader = _make_loader({
		"a": {"b": {"c": "res://deep/value.gd"}}
	})
	assert_str(loader.get_path("a.b.c")).is_equal("res://deep/value.gd")

func test_get_path_missing_key_returns_empty_and_logs_error() -> void:
	var loader: FilePathsLoader = _make_loader({"scenes": {}})
	var result := loader.get_path("scenes.missing")
	assert_str(result).is_empty()
	assert_that(loader.get_errors().size()).is_greater(0)

func test_get_path_value_not_string_returns_empty_and_logs_error() -> void:
	var loader: FilePathsLoader = _make_loader({
		"scenes": {"nested": {"deeper": "val"}}
	})
	# "scenes.nested" resolves to a Dictionary, not a String
	var result := loader.get_path("scenes.nested")
	assert_str(result).is_empty()
	assert_that(loader.get_errors().size()).is_greater(0)

# ---------------------------------------------------------------------------
# get_category
# ---------------------------------------------------------------------------

func test_get_category_returns_dict_for_known_category() -> void:
	var loader: FilePathsLoader = _make_loader({
		"autoloads": {"settings": "res://Autoloads/settings.gd"}
	})
	var cat := loader.get_category("autoloads")
	assert_that(cat.has("settings")).is_true()

func test_get_category_missing_category_returns_empty() -> void:
	var loader: FilePathsLoader = _make_loader({})
	var cat := loader.get_category("scenes")
	assert_dict(cat).is_empty()

func test_get_category_value_not_dict_returns_empty() -> void:
	var loader: FilePathsLoader = _make_loader({
		"scenes": "not_a_dict"
	})
	var cat := loader.get_category("scenes")
	assert_dict(cat).is_empty()

# ---------------------------------------------------------------------------
# get_warnings
# ---------------------------------------------------------------------------

func test_get_warnings_returns_warnings_from_meta() -> void:
	var loader: FilePathsLoader = _make_loader({
		"_meta": {"warnings": ["warn A", "warn B"]}
	})
	var warnings := loader.get_warnings()
	assert_int(warnings.size()).is_equal(2)
	assert_str(warnings[0]).is_equal("warn A")

func test_get_warnings_empty_when_no_meta() -> void:
	var loader: FilePathsLoader = _make_loader({})
	assert_int(loader.get_warnings().size()).is_equal(0)

func test_get_warnings_empty_when_meta_has_no_warnings_key() -> void:
	var loader: FilePathsLoader = _make_loader({"_meta": {}})
	assert_int(loader.get_warnings().size()).is_equal(0)

# ---------------------------------------------------------------------------
# get_dynamic_paths
# ---------------------------------------------------------------------------

func test_get_dynamic_paths_returns_dynamic_section() -> void:
	var loader: FilePathsLoader = _make_loader({
		"dynamic_paths": {"levels": "res://levels/{id}.tres"}
	})
	var dyn := loader.get_dynamic_paths()
	assert_that(dyn.has("levels")).is_true()

func test_get_dynamic_paths_empty_when_missing() -> void:
	var loader: FilePathsLoader = _make_loader({})
	assert_dict(loader.get_dynamic_paths()).is_empty()

# ---------------------------------------------------------------------------
# print_summary (smoke test — just confirm it doesn't crash)
# ---------------------------------------------------------------------------

func test_print_summary_does_not_crash() -> void:
	var loader: FilePathsLoader = _make_loader({
		"scenes": {"game": "res://Main.tscn"},
		"autoloads": {"db": "res://Autoloads/DB.gd"}
	})
	loader.print_summary() # Should just log to console without crashing
	assert_bool(true).is_true()

# ---------------------------------------------------------------------------
# validate_paths
# ---------------------------------------------------------------------------

func test_validate_paths_detects_valid_resources() -> void:
	# Using this very test script as the guaranteed existing resource
	var valid_path: String = "res://tests/test_file_paths_loader.gd"
	var loader: FilePathsLoader = _make_loader({
		"scenes": {
			"my_scene": valid_path
		}
	})
	var results = loader.validate_paths()
	assert_int(results["total_checked"]).is_equal(1)
	assert_int(results["valid"].size()).is_equal(1)
	assert_str(results["valid"][0]).is_equal(valid_path)
	assert_int(results["missing"].size()).is_equal(0)

func test_validate_paths_detects_missing_resources() -> void:
	var loader: FilePathsLoader = _make_loader({
		"resources": {
			"nested": {
				"bad_path": "res://tests/does_not_exist_xyz.tres"
			}
		}
	})
	var results = loader.validate_paths()
	assert_int(results["total_checked"]).is_equal(1)
	assert_int(results["valid"].size()).is_equal(0)
	assert_int(results["missing"].size()).is_equal(1)
	assert_str(results["missing"][0]["path"]).is_equal("res://tests/does_not_exist_xyz.tres")
	assert_str(results["missing"][0]["category"]).is_equal("resources.nested.bad_path")

func test_validate_paths_checks_directory_paths() -> void:
	# Provide an existing directory vs missing
	var loader: FilePathsLoader = _make_loader({
		"directories": {
			"tests_folder": "res://tests/",
			"missing_folder": "res://some/missing/dir/"
		}
	})
	var results = loader.validate_paths()
	# One valid, one missing
	assert_int(results["total_checked"]).is_equal(2)
	assert_int(results["valid"].size()).is_equal(1)
	assert_int(results["missing"].size()).is_equal(1)
	var missing_path = results["missing"][0]["path"]
	assert_str(missing_path).is_equal("res://some/missing/dir/")
