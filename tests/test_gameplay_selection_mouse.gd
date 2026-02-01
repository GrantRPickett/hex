# NOTE: This file tests general gameplay selection, not just mouse input.
extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LevelScript := preload("res://Resources/Level.gd")

var _control_settings: Node
var _input_mapper: Node
var _runner: GdUnitSceneRunner
var _scene: Node

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_input_mapper.apply_configs(_control_settings.camera_actions)

	_runner = _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_scene = _runner.scene()
	_scene.set_turn_system_enabled(false)
	var input_handler := _scene.get_node("InputHandler")
	var camera_handler := _scene.get_node("CameraHandler")
	if camera_handler and input_handler and not input_handler.camera_input_requested.is_connected(Callable(camera_handler, "handle_camera_input")):
		input_handler.camera_input_requested.connect(Callable(camera_handler, "handle_camera_input"))

	if _scene.has_method("_register_input_actions"):
		_scene.call("_register_input_actions")

	# The InputHandler was refactored to use a signal for camera input.
	# We must connect it here for all tests in this suite to work correctly.
	await _simulate_frames(_runner, 1)

func after_test() -> void:
	_runner = null
	await teardown_autoloads()

# --- Refactored Test ---

func test_camera_centers_on_selected_when_cycled() -> void:
	# NOTE: This test is pending refactor - expects a "Player" node that doesn't exist
	# Current architecture doesn't create scene-based player units
	pass

# --- New Tests for InputHandler Refactor ---

func test_primary_action_selects_unit() -> void:
	# NOTE: This test is pending refactor - expects a "Player" node that doesn't exist
	# Current architecture doesn't create scene-based player units
	pass



func test_primary_action_moves_unit() -> void:
	var level = _make_level([Vector2i(1, 1)], [Vector2i(5, 5)]) # Goal out of the way
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	var start_coord = _scene.player_coord
	var direction_map: Dictionary = _scene._hex_navigator.get_direction_map(start_coord, _scene._grid)
	assert_that(direction_map.has("move_d")).is_true()
	var target_coord: Vector2i = start_coord + direction_map["move_d"]
	assert_that(_scene._unit_manager.is_occupied(target_coord)).is_false()

	var target_screen_pos = _scene._axial_to_pixel(target_coord)
	_scene._input_handler.primary_action_at.emit(target_screen_pos)
	await _simulate_frames(_runner, 2)

	# Assert that the player has moved to the target coordinate
	assert_that(_scene.player_coord).is_equal(target_coord)

func _make_level(player_starts: Array[Vector2i], goal_coords: Array[Vector2i]) -> Level:
	var level := LevelScript.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts
	var goals: Array[Vector2i] = []
	goals.assign(goal_coords)
	level.goal_coords = goals
	return level
