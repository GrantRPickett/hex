extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

var _gameplay_instance: Node

func before_test() -> void:
	await HexTestUtils.setup_autoloads(get_tree(), AUTOLOADS)
	_gameplay_instance = load(GAMEPLAY_SCENE_PATH).instantiate()
	get_tree().root.add_child(_gameplay_instance)
	# Wait for _ready to fire and register actions
	await get_tree().process_frame

func after_test() -> void:
	await HexTestUtils.free_tree(_gameplay_instance)
	await HexTestUtils.teardown_autoloads(get_tree())

	# Clean up actions to prevent side effects on other tests
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS
	]
	for group in groups:
		for entry in group:
			var action: String = entry["action"]
			if InputMap.has_action(action):
				InputMap.erase_action(action)

func test_input_actions_are_registered_in_inputmap() -> void:
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS
	]

	for group in groups:
		for entry in group:
			var action: String = entry["action"]
			assert_that(InputMap.has_action(action)) \
				.override_failure_message("Action '%s' defined in InputActions was not found in InputMap." % action) \
				.is_true()
