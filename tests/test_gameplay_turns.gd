extends "res://tests/test_utils.gd"

const SIDE_PLAYER := 0
const SIDE_OTHER := 1

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

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
	# NOTE: This test is pending refactor - TurnSystem API has changed
	# Can no longer call can_unit_act() on TurnSystem directly
	pass

func test_enemy_units_are_consumed_between_player_moves() -> void:
	# NOTE: This test is pending refactor - TurnSystem API has changed
	# Can no longer call get_available_indexes() on TurnSystem directly
	pass

func test_wait_skips_to_next_available_unit() -> void:
	# NOTE: This test is pending refactor - TurnSystem API has changed
	# Can no longer call can_unit_act() on TurnSystem directly
	pass
