extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _control_settings: Node
var _input_mapper: Node

class MockInputMapper extends Node:
	func apply_configs(_actions: Array, _defaults: Array = []) -> void:
		pass

func before_test() -> void:
	_control_settings = await ensure_manager("ControlSettings", "res://Autoloads/control_settings.gd")
	if not get_tree().root.has_node("InputMapper"):
		_input_mapper = MockInputMapper.new()
		_input_mapper.name = "InputMapper"
		get_tree().root.add_child(_input_mapper)

func after_test() -> void:
	if is_instance_valid(_control_settings):
		_control_settings.queue_free()
	if is_instance_valid(_input_mapper):
		_input_mapper.queue_free()
	await get_tree().process_frame

func _set_axis(scene: Node, axis: Vector2) -> void:
	scene.set_joy_axis(axis)

func _wait_for_player_coord_change(runner, scene, old_coord: Vector2i, max_frames: int) -> bool:
	for i in range(max_frames):
		_simulate_frames(runner, 1)
		if scene.player_coord != old_coord:
			return true
	return false
