extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func test_camera_centers_on_selected() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var handler = scene.get_node("CameraHandler")
	var cam = handler.get_node(handler.camera_node)
	var p1: Node2D = scene.get_node("Player")
	var p2: Node2D = scene.get_node("Player2")

	# Starts centered on P1
	assert_that(cam.position).is_equal(p1.position)

	# Cycle selection via internal helper and center should change to P2
	scene._cycle_selection(1)
	_simulate_frames(runner, 1)
	assert_that(cam.position).is_equal(p2.position)

func test_left_click_selects_player() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var player2: Node2D = scene.get_node("Player2")
	_simulate_frames(runner, 1)
	assert_that(scene._selected_index).is_equal(1)
