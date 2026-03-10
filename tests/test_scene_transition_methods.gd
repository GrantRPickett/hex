extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
const AUTOLOADS = {
	"SceneTransition": "res://Autoloads/scene_transition.gd",
	"ControlSettings": "res://Autoloads/control_settings.gd",
}

var _scene_transition: Node

func before_test() -> void:
	var instances = await HexTestUtils.setup_autoloads(get_tree(), AUTOLOADS)
	_scene_transition = instances["SceneTransition"]

func after_test() -> void:
	await HexTestUtils.teardown_autoloads(get_tree())

func test_is_changing() -> void:
	assert_that(_scene_transition.is_changing()).is_false()

	# Start a transition with a delay so we can catch the state
	_scene_transition.change_scene("res://Menus/title_screen.tscn", 0.1)
	assert_that(_scene_transition.is_changing()).is_true()

	await _scene_transition.scene_change_completed
	assert_that(_scene_transition.is_changing()).is_false()
