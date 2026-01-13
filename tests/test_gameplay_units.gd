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

func test_unit_cannot_move_into_occupied_tile() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await _simulate_frames(runner, 1)

	# Setup: Place Player 1 at (0, 0)
	scene.set_player_coord(Vector2i(0, 0))

	# Add blocking unit at (0, 1)
	var blocker = scene.get_node("Player").duplicate()
	scene.add_child(blocker)
	scene.add_unit(blocker, Vector2i(0, 1), true)

	await _simulate_frames(runner, 1)

	# Select Player 1 (index 0)
	scene._selected_index = 0

	# Try to move South (0, 1) which is occupied
	# (0,0) is even column, move_s is (0,1)
	scene.request_move("move_s")
	await _simulate_frames(runner, 5)

	# Assert position hasn't changed
	assert_that(scene.player_coord).is_equal(Vector2i(0, 0))

	# Move East (1, 0) should work (unoccupied)
	# (0,0) even col, move_d is (1,0)
	scene.request_move("move_d")
	await _simulate_frames(runner, 1)
	assert_that(scene.player_coord).is_equal(Vector2i(1, 0))

func test_cannot_select_enemy_unit_via_click() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await _simulate_frames(runner, 1)

	# Add a second unit
	var p2 = scene.get_node("Player").duplicate()
	scene.add_child(p2)
	scene.add_unit(p2, Vector2i(2, 2), true)

	# Set unit 1 (Player 2) as enemy
	scene.set_unit_controlled_by_player(1, false)

	# Ensure unit 0 is selected
	scene._selected_index = 0

	# Simulate click on unit 1
	var p2_pos = p2.position
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = p2_pos
	scene._unhandled_input(event)
	await _simulate_frames(runner, 1)

	# Assert selection did not change
	assert_that(scene._selected_index).is_equal(0)

func test_cycling_skips_enemy_units() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await _simulate_frames(runner, 1)

	# Add unit 1
	var p2 = scene.get_node("Player").duplicate()
	scene.add_child(p2)
	scene.add_unit(p2, Vector2i(1, 1), true)

	# Add a 3rd unit to test skipping middle one
	var p3 = scene.get_node("Player").duplicate()
	scene.add_child(p3)
	# Place at (2,2)
	scene.add_unit(p3, Vector2i(2, 2), true)

	# Now we have indices 0, 1, 2.
	# Set index 1 as enemy.
	scene.set_unit_controlled_by_player(1, false)

	# Select 0
	scene._selected_index = 0

	# Cycle next (should skip 1 and go to 2)
	scene._cycle_selection(1)
	await _simulate_frames(runner, 1)
	assert_that(scene._selected_index).is_equal(2)

	# Cycle next (should go back to 0)
	scene._cycle_selection(1)
	await _simulate_frames(runner, 1)
	assert_that(scene._selected_index).is_equal(0)

func test_dynamic_control_change() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await _simulate_frames(runner, 1)

	# Add unit 1
	var p2 = scene.get_node("Player").duplicate()
	scene.add_child(p2)
	scene.add_unit(p2, Vector2i(1, 1), true)

	# Set unit 1 as enemy
	scene.set_unit_controlled_by_player(1, false)

	# Try to select it via cycle (should fail/skip)
	scene._selected_index = 0
	scene._cycle_selection(1)
	# With only 2 units and 1 disabled, it stays on 0
	assert_that(scene._selected_index).is_equal(0)

	# Give control back
	scene.set_unit_controlled_by_player(1, true)

	# Cycle (should now select 1)
	scene._cycle_selection(1)
	assert_that(scene._selected_index).is_equal(1)