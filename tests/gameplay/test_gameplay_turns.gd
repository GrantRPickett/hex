extends "res://tests/test_utils.gd"

const TurnSystem := preload("res://Gameplay/turn_system.gd")
const SIDE_PLAYER := 0
const SIDE_OTHER := 1

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LevelScript = preload("res://Resources/Level.gd")

const AUTOLOADS := {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

var _runner: GdUnitSceneRunner
var _scene: Node
var _control_settings: Node
var _input_mapper: Node

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
	await _simulate_frames(_runner, 1)

func after_test() -> void:
	_runner = null
	await teardown_autoloads()

func _expected_coord_for(action: String, index: int) -> Vector2i:
	var current: Vector2i = _scene._unit_manager.get_coord(index)
	var directions: Dictionary = _scene._hex_navigator.get_direction_map(current, _scene._grid)
	if not directions.has(action):
		return current
	return current + directions[action]

func test_player_unit_cannot_move_twice_before_turn_resets() -> void:
	var level :	LevelScript= auto_free(LevelScript.new())
	level.player_starts = [Vector2i(0, 0), Vector2i(5, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0), Vector2i(5, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	_scene._on_select_index_requested(0)
	_scene.request_move("move_d")
	await _simulate_frames(_runner, 2)
	var first_move_coord: Vector2i = _scene._unit_manager.get_coord(0)
	assert_that(first_move_coord).is_not_equal(Vector2i(0, 0))
	assert_bool(_scene._turn_system.can_unit_act(0)).is_false()

	_scene.request_move("move_d")
	await _simulate_frames(_runner, 2)
	assert_that(_scene._unit_manager.get_coord(0)).is_equal(first_move_coord)

	_scene._on_select_index_requested(1)
	_scene.request_move("move_a")
	await _simulate_frames(_runner, 2)
	assert_that(_scene._unit_manager.get_coord(1)).is_equal(Vector2i(5, 1))

	_scene._on_select_index_requested(0)
	assert_bool(_scene._turn_system.can_unit_act(0)).is_true()
	_scene.request_move("move_d")
	await _simulate_frames(_runner, 2)

func test_enemy_units_are_consumed_between_player_moves() -> void:
	var level :	LevelScript= auto_free(LevelScript.new())
	level.player_starts = [Vector2i(0, 0), Vector2i(5, 0)] as Array[Vector2i]
	level.enemy_starts = [Vector2i(3, 3)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0), Vector2i(5, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	_scene._on_select_index_requested(0)
	_scene.request_move("move_d")
	await _simulate_frames(_runner, 20)
	assert_array(_scene._turn_system.get_available_indexes(SIDE_OTHER)).is_empty()

	_scene._on_select_index_requested(1)
	var player_two_target := _expected_coord_for("move_a", 1)
	_scene.request_move("move_a")
	await _simulate_frames(_runner, 2)
	var available_players: Array[int] = _scene._turn_system.get_available_indexes(SIDE_PLAYER)
	assert_bool(available_players.has(0)).is_true()

	_scene._on_select_index_requested(0)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._unit_manager.get_coord(1)).is_equal(player_two_target)

func test_wait_skips_to_next_available_unit() -> void:
	var level :	LevelScript= auto_free(LevelScript.new())
	level.player_starts = [Vector2i(0, 0), Vector2i(2, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(0, 0), Vector2i(2, 0)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	_scene._on_select_index_requested(0)
	_scene._on_wait_requested()
	await _simulate_frames(_runner, 1)
	assert_bool(_scene._turn_system.can_unit_act(0)).is_false()
	assert_int(_scene._unit_manager.get_selected_index()).is_equal(1)

	_scene._on_select_index_requested(0)
	await _simulate_frames(_runner, 1)
	assert_int(_scene._unit_manager.get_selected_index()).is_equal(1)

	_scene._on_select_index_requested(1)
	var wait_move_target := _expected_coord_for("move_a", 1)
	_scene.request_move("move_a")
	await _simulate_frames(_runner, 2)
	assert_bool(_scene._turn_system.can_unit_act(0)).is_true()
	assert_that(_scene._unit_manager.get_coord(1)).is_equal(wait_move_target)
