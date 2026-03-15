extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
# Test coverage for menu callback functions

const CREDITS_SCENE := "res://Menus/credits.tscn"
const TITLE_SCENE := "res://Menus/title_screen.tscn"

var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	# Ensure ControlSettings autoload is properly initialized
	_control_settings = await HexTestUtils.ensure_manager(get_tree(), "ControlSettings", "res://Autoloads/control_settings.gd")
	_input_mapper = await HexTestUtils.ensure_manager(get_tree(), "InputMapper", "res://Autoloads/input_mapper.gd")

func after_test() -> void:
	if is_instance_valid(_control_settings):
		_control_settings.queue_free()
	if is_instance_valid(_input_mapper):
		_input_mapper.queue_free()
	await get_tree().process_frame

func test_credits_set_return_delay() -> void:
	var runner := HexTestUtils._create_scene_runner(self, CREDITS_SCENE)
	var scene := runner.scene()
	HexTestUtils._simulate_frames(runner, 1)

	assert_that(scene).is_not_null()

	# Test setting custom delays
	var delay1 := 0.5
	scene.set_return_delay(delay1)
	HexTestUtils._simulate_frames(runner, 1)
	assert_that(scene.return_delay).is_equal(delay1)

	var delay2 := 2.0
	scene.set_return_delay(delay2)
	HexTestUtils._simulate_frames(runner, 1)
	assert_that(scene.return_delay).is_equal(delay2)

func test_title_screen_set_quit_callback() -> void:
	var runner := HexTestUtils._create_scene_runner(self, TITLE_SCENE)
	var scene := runner.scene()
	HexTestUtils._simulate_frames(runner, 1)

	assert_that(scene).is_not_null()

	# Create a test callback
	var was_called := [false]
	var test_callback: Callable = func():
		was_called[0] = true

	# Set the callback
	scene.set_quit_callback(test_callback)
	HexTestUtils._simulate_frames(runner, 1)

	# Verify callback was stored (access private member for test verification)
	assert_that(scene._quit_callback.is_null()).is_false()
