extends GdUnitTestSuite


const HexTestUtils = preload("res://tests/base_test_suite.gd")
var _display_settings: DisplaySettingsManager

func before_test() -> void:
	_display_settings = await HexTestUtils.ensure_manager(get_tree(), "DisplaySettings", "res://Autoloads/display_settings.gd")
	_display_settings.set_orientation(DisplayOrientation.Orientation.LANDSCAPE)
	_display_settings.set_resolution_index(2)

func after_test() -> void:
	if is_instance_valid(_display_settings):
		_display_settings.queue_free()
	await get_tree().process_frame

func test_get_standard_resolutions_includes_landscape_options() -> void:
	var landscape := _display_settings.get_standard_resolutions(DisplayOrientation.Orientation.LANDSCAPE)
	assert_that(landscape.size()).is_greater(0)
	for res in landscape:
		assert_bool(res.x >= res.y).is_true()

func test_set_orientation_switches_current_resolution_pool() -> void:
	_display_settings.set_orientation(DisplayOrientation.Orientation.PORTRAIT)
	assert_that(_display_settings.get_current_orientation()).is_equal(DisplayOrientation.Orientation.PORTRAIT)
	var portrait := _display_settings.get_standard_resolutions(DisplayOrientation.Orientation.PORTRAIT)
	assert_that(_display_settings.get_current_resolution()).is_equal(portrait[_display_settings.get_current_resolution_index()])

func test_set_resolution_index_clamps_to_available_range() -> void:
	var options := _display_settings.get_standard_resolutions(_display_settings.get_current_orientation())
	_display_settings.set_resolution_index(options.size() + 5)
	assert_that(_display_settings.get_current_resolution_index()).is_equal(options.size() - 1)

func test_display_orientation_string_conversions() -> void:
	assert_that(DisplayOrientation.from_string("portrait")).is_equal(DisplayOrientation.Orientation.PORTRAIT)
	assert_that(DisplayOrientation.from_string("LANDSCAPE")).is_equal(DisplayOrientation.Orientation.LANDSCAPE)
	assert_that(DisplayOrientation.to_name(DisplayOrientation.Orientation.LANDSCAPE)).is_equal("landscape")
	assert_that(DisplayOrientation.to_name(DisplayOrientation.Orientation.PORTRAIT)).is_equal("portrait")
