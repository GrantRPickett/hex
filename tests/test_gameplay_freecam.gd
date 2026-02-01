extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LevelScript := preload("res://Resources/Level.gd")

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

var _control_settings: Node
var _input_mapper: Node
var _runner: GdUnitSceneRunner
var _scene: Node

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = StringName(action)
	ev.pressed = true
	return ev

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

	await _simulate_frames(_runner, 1)

	var scene_tree := _scene.get_tree()
	if scene_tree:
		scene_tree.paused = false
		assert_that(scene_tree.paused).is_false()
	
func after_test() -> void:
	_runner = null
	await teardown_autoloads()

func _make_level(player_starts: Array[Vector2i], goal_coords: Array[Vector2i]) -> Level:
	var level := LevelScript.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts
	var goals: Array[Vector2i] = []
	goals.assign(goal_coords)
	level.goal_coords = goals
	return level

func test_toggle_free_cam_action() -> void:
	var camera_handler := _scene.get_node("CameraHandler")
	assert_that(camera_handler.is_free_cam()).is_false()

	# Simulate the action to toggle free cam ON
	_scene._input_handler._unhandled_input(_action_event("toggle_free_cam"))
	await _simulate_frames(_runner, 1)
	assert_that(camera_handler.is_free_cam()).is_true()

	# Simulate the action again to toggle free cam OFF
	_scene._input_handler._unhandled_input(_action_event("toggle_free_cam"))
	await _simulate_frames(_runner, 1)
	assert_that(camera_handler.is_free_cam()).is_false()


func test_free_cam_disables_centering_on_selection_cycle() -> void:
	# Setup a level with two units
	var level = _make_level([Vector2i(1, 1), Vector2i(3, 3)], [Vector2i(5, 5)])
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	var camera_handler := _scene.get_node("CameraHandler")
	var cam := camera_handler.get_node(camera_handler.camera_node)

	# Toggle free cam ON
	_scene._input_handler._unhandled_input(_action_event("toggle_free_cam"))
	await _simulate_frames(_runner, 1)
	assert_that(camera_handler.is_free_cam()).is_true()

	# Manually move the camera to a different position
	var free_cam_pos = Vector2(500, 500)
	cam.position = free_cam_pos
	await _simulate_frames(_runner, 1)
	assert_that(cam.position).is_equal(free_cam_pos)

	# Cycle selection
	# This should NOT center the camera because free cam is on.
	_scene._input_handler.selection_cycle_requested.emit(1)
	await _simulate_frames(_runner, 1)

	assert_that(_scene._unit_manager.get_selected_index()).is_equal(1)
	assert_that(cam.position).is_equal(free_cam_pos) # Assert camera did NOT move
