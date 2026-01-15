extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LevelScript = preload("res://Resources/Level.gd")

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

	# Connect the InputHandler signal to CameraHandler as per refactor
	await _simulate_frames(_runner, 1)

func after_test() -> void:
	_runner = null
	await teardown_autoloads()

func _expected_coord_for(index: int, action: String) -> Vector2i:
	var current: Vector2i = _scene._unit_manager.get_coord(index)
	var directions: Dictionary = _scene._hex_navigator.get_direction_map(current, _scene._grid)
	if not directions.has(action):
		return current
	return current + directions[action]

func test_unit_cannot_move_into_occupied_tile() -> void:
	# Reset level to known state (1 unit at 0,0)
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Add blocking unit at (0, 1)
	var blocker = _scene.get_node("Player").duplicate()
	_scene.add_child(blocker)
	_scene.add_unit(blocker, Vector2i(0, 1), true)

	await _simulate_frames(_runner, 1)

	# Select Player 1 (index 0)
	_scene._on_select_index_requested(0)

	# Try to move South (0, 1) which is occupied
	# (0,0) is even column, move_s is (0,1)
	var blocked_target := _expected_coord_for(0, "move_s")
	_scene.request_move("move_s")
	await _simulate_frames(_runner, 5)

	# Assert position hasn't changed
	assert_that(_scene.player_coord).is_not_equal(blocked_target)

	# Move East (1, 0) should work (unoccupied)
	# (0,0) even col, move_d is (1,0)
	var open_target := _expected_coord_for(0, "move_d")
	_scene.request_move("move_d")
	await _simulate_frames(_runner, 1)
	assert_that(_scene.player_coord).is_equal(open_target)

func test_cannot_select_enemy_unit_via_click() -> void:
	# Reset level to known state (1 unit at 0,0)
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Add a second unit
	var p2 = _scene.get_node("Player").duplicate()
	_scene.add_child(p2)
	_scene.add_unit(p2, Vector2i(2, 2), true)

	# Set unit 1 (Player 2) as enemy
	_scene.set_unit_controlled_by_player(1, false)

	# Ensure unit 0 is selected
	_scene._on_select_index_requested(0)

	# Simulate click on unit 1
	var p2_pos = p2.get_global_transform_with_canvas().origin
	await _runner.simulate_mouse_move(p2_pos)
	await _runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await _simulate_frames(_runner, 1)

	# Assert selection did not change
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(0)

func test_cycling_skips_enemy_units() -> void:
	# Reset level to known state (1 unit at 0,0)
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Add unit 1
	var p2 = _scene.get_node("Player").duplicate()
	_scene.add_child(p2)
	_scene.add_unit(p2, Vector2i(1, 1), true)

	# Add a 3rd unit to test skipping middle one
	var p3 = _scene.get_node("Player").duplicate()
	_scene.add_child(p3)
	# Place at (2,2)
	_scene.add_unit(p3, Vector2i(2, 2), true)

	# Now we have indices 0, 1, 2.
	# Set index 1 as enemy.
	_scene.set_unit_controlled_by_player(1, false)

	# Select 0
	_scene._on_select_index_requested(0)

	# Cycle next (should skip 1 and go to 2)
	_scene._on_selection_cycle_requested(1)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(2)

	# Cycle next (should go back to 0)
	_scene._on_selection_cycle_requested(1)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(0)

func test_dynamic_control_change() -> void:
	# Reset level to a known state with one player unit to avoid state
	# leaking from the default scene's level resource.
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Add unit 1
	var p2 = _scene.get_node("Player").duplicate()
	_scene.add_child(p2)
	_scene.add_unit(p2, Vector2i(1, 1), true)

	# Try to select it via cycle (should fail/skip)
	_scene._on_select_index_requested(0)
	_scene.set_unit_controlled_by_player(1, false) # Make unit 1 an enemy
	_scene._on_selection_cycle_requested(1)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(0)

	# Give control back
	_scene.set_unit_controlled_by_player(1, true)

	# Cycle (should now select 1)
	_scene._on_selection_cycle_requested(1)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._unit_manager.get_selected_index()).is_equal(1)

func test_enemies_spawn_from_level_resource() -> void:
	var level = LevelScript.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.enemy_starts = [Vector2i(1, 2), Vector2i(2, 2)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0)] as Array[Vector2i]

	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Expect all player and enemy units to spawn from their respective start positions
	assert_that(_scene._unit_manager.get_unit_count()).is_equal(3)

	# Unit 0 (Player)
	assert_that(_scene._unit_manager.get_coord(0)).is_equal(Vector2i(0, 0))
	assert_that(_scene._unit_manager.is_player_controlled(0)).is_true()

	# Unit 1 (Enemy)
	assert_that(_scene._unit_manager.get_coord(1)).is_equal(Vector2i(1, 2))
	assert_that(_scene._unit_manager.is_player_controlled(1)).is_false()

	# Unit 2 (Enemy)
	assert_that(_scene._unit_manager.get_coord(2)).is_equal(Vector2i(2, 2))
	assert_that(_scene._unit_manager.is_player_controlled(2)).is_false()
