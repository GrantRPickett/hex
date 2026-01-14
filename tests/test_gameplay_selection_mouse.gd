# NOTE: This file tests general gameplay selection, not just mouse input.
extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

class UnitTestLevel extends Resource:
	var player_starts: Array[Vector2i] = []
	var goal_coords: Array[Vector2i] = []
	var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var require_all_units: bool = false
	var initial_rotation: float = 0.0
	var grid_width: int = 7
	var grid_height: int = 7

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
	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.goal_coords = [Vector2i(1, 1)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	var handler = _scene.get_node("CameraHandler")
	var cam = handler.get_node(handler.camera_node)
	var p1: Node2D = _scene.get_node("Player")

	var p2 = p1.duplicate()
	_scene.add_child(p2)
	_scene.add_unit(p2, Vector2i(2, 2), true)

	# Starts centered on P1
	assert_that(cam.position).is_equal(p1.position)

	# Cycle selection by emitting the signal from the input handler
	_scene._input_handler.selection_cycle_requested.emit(1)
	await _simulate_frames(_runner, 1)

	assert_that(cam.position).is_equal(p2.position)

# --- New Tests for InputHandler Refactor ---

func test_primary_action_selects_unit() -> void:
	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.goal_coords = [Vector2i(1, 1)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	var p2_coord = Vector2i(2, 2)
	var p2 = _scene.get_node("Player").duplicate()
	_scene.add_child(p2)
	_scene.add_unit(p2, p2_coord, true)
	await _simulate_frames(_runner, 1)

	# P1 (index 0) is selected by default
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(0)

	# Simulate a click on P2's position
	var p2_screen_pos = _scene._axial_to_pixel(p2_coord)
	_scene._input_handler.primary_action_at.emit(p2_screen_pos)
	await _simulate_frames(_runner, 1)

	# Assert that P2 (index 1) is now selected
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(1)


func test_primary_action_moves_unit() -> void:
	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(1, 1)] as Array[Vector2i]
	level.goal_coords = [Vector2i(5, 5)] as Array[Vector2i] # Goal out of the way
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	var start_coord = _scene.player_coord
	# 'd' on the hex grid corresponds to a + (1, 0) change in axial coordinates
	var target_coord = start_coord + Vector2i(1, 0)

	# Ensure target cell is empty before click
	assert_that(_scene._unit_manager.is_occupied(target_coord)).is_false()

	# Simulate a click on the target cell
	var target_screen_pos = _scene._axial_to_pixel(target_coord)
	_scene._input_handler.primary_action_at.emit(target_screen_pos)
	await _simulate_frames(_runner, 2) # Allow for move lock to release

	# Assert that the player has moved to the target coordinate
	assert_that(_scene.player_coord).is_equal(target_coord)
