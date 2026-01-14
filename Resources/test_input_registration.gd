extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const InputActions := preload("res://Resources/input_actions.gd")

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

var _runner: GdUnitSceneRunner

func before_test() -> void:
	await setup_autoloads(AUTOLOADS)
	_runner = _create_scene_runner(GAMEPLAY_SCENE_PATH)
	# Wait for _ready to fire and register actions
	await _runner.simulate_frames(1)

func after_test() -> void:
	_runner = null
	await teardown_autoloads()

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