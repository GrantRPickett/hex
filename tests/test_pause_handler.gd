extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
const PAUSE_HANDLER_SCRIPT = preload("res://Menus/pause_handler.gd")
const PAUSE_MENU_SCENE = preload("res://Menus/pause_menu.tscn") # Not directly used, but good for context

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _runner: GdUnitSceneRunner
var _pause_handler_instance: Node
var _control_settings: Node
var _input_mapper: Node
var _event_bus: Node
var _scene_transition: Node

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
	"EventBus": "res://Autoloads/event_bus.gd",
	"SceneTransition": "res://Autoloads/scene_transition.gd",
}

func before_test() -> void:
	# Ensure core autoloads are set up
	var instances = await HexTestUtils.setup_autoloads(get_tree(), AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_event_bus = instances["EventBus"]
	_scene_transition = instances["SceneTransition"]

	# Create a scene runner for the gameplay scene to get the PauseHandler
	_runner = HexTestUtils._create_scene_runner(self, GAMEPLAY_SCENE_PATH)
	await HexTestUtils._simulate_frames(_runner, 1) # Allow scene to initialize

	# Find the PauseHandler instance within the loaded scene
	# Assuming the PauseHandler node itself is named "PauseHandler" within the scene.
	# If this fails, further investigation into Gameplay.tscn is needed to find its actual name/path.
	_pause_handler_instance = _runner.scene().find_child("PauseHandler", true, false)
	assert_that(_pause_handler_instance).is_not_null()

	# Ensure the game is not paused at the start of each test
	if _pause_handler_instance.is_paused():
		_pause_handler_instance._hide_pause_menu()
		get_tree().paused = false # Also ensure the tree is unpaused

	# Ensure "pause_game" action is registered for tests
	# This action is usually registered by Gameplay.gd through InputMapper
	# but tests might run without full Gameplay scene setup.
	if _control_settings != null and _input_mapper != null:
		_input_mapper.apply_configs(_control_settings.pause_actions)

	# Unconditionally ensure the "pause_game" action is in InputMap for tests
	if not InputMap.has_action("pause_game"):
		InputMap.add_action("pause_game")
	if InputMap.action_get_events("pause_game").is_empty():
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_ESCAPE # Default pause key
		InputMap.action_add_event("pause_game", key_event)

func after_test() -> void:
	_runner = null
	await HexTestUtils.teardown_autoloads(get_tree())

	# Clear the manually added pause_game action if it was added
	if InputMap.has_action("pause_game"):
		InputMap.erase_action("pause_game")
	await get_tree().process_frame


func test_handle_pause_input_toggles_state() -> void:
	# The _pause_handler_instance is already set up in before_test()
	# We don't need a new runner here, as the handler is already part of the test setup.
	var pause_event := InputEventAction.new()
	pause_event.action = "pause_game"
	pause_event.pressed = true

	# First press: should pause the game
	_pause_handler_instance._unhandled_input(pause_event)
	await get_tree().process_frame # Simulate a frame for the pause menu to appear
	assert_that(_pause_handler_instance.is_paused()).is_true()

	# Second press: should unpause the game
	_pause_handler_instance._unhandled_input(pause_event)
	await get_tree().process_frame # Simulate a frame for the pause menu to disappear
	assert_that(_pause_handler_instance.is_paused()).is_false()
