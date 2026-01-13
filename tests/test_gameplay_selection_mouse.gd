extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _control_settings: Node
var _input_mapper: Node

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func test_camera_centers_on_selected() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var handler = scene.get_node("CameraHandler")
	var cam = handler.get_node(handler.camera_node)
	var p1: Node2D = scene.get_node("Player")

	var p2 = p1.duplicate()
	scene.add_child(p2)
	scene.add_unit(p2, Vector2i(2, 2), true)

	# Starts centered on P1
	assert_that(cam.position).is_equal(p1.position)

	# Cycle selection via internal helper and center should change to P2
	scene._cycle_selection(1)
	_simulate_frames(runner, 1)
	assert_that(cam.position).is_equal(p2.position)
