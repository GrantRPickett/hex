extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level_1.tres"
const POST_COMPLETION_LEVEL_SELECT_SCENE := "res://Menus/level_select.tscn"
const SCENE_CHANGE_TIMEOUT_FRAMES := 600

var _level_manager: Node
var _save_manager: Node
var _scene_transition: Node
var _control_settings: Node
var _input_mapper: Node

const AUTOLOADS = {
	"SaveManager": "res://Autoloads/save_manager.gd",
	"LevelManager": "res://Autoloads/level_manager.gd",
	"SceneTransition": "res://Autoloads/scene_transition.gd",
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_save_manager = instances["SaveManager"]
	_level_manager = instances["LevelManager"]
	_scene_transition = instances["SceneTransition"]
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_clear_save_game()

func after_test() -> void:
	await teardown_autoloads()


func _vector_to_action(scene: Node, from: Vector2i, delta: Vector2i) -> String:
	var dir_map: Dictionary = scene._direction_map(from)
	for k in dir_map.keys():
		if dir_map[k] == delta:
			return k
	return ""

func _await_scene_change(runner: GdUnitSceneRunner, tree: SceneTree, context: String) -> void:
	var result := [false]
	var handler := func () -> void:
		result[0] = true
	tree.scene_changed.connect(handler)
	var frames := 0
	while not result[0] and frames < SCENE_CHANGE_TIMEOUT_FRAMES:
		await _simulate_frames(runner, 1)
		frames += 1
	if tree.scene_changed.is_connected(handler):
		tree.scene_changed.disconnect(handler)
	assert_that(result[0]).is_true() #is_true() takes no arguments
