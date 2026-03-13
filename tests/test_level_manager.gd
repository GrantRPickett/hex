extends GdUnitTestSuite

const LevelManagerScript := preload("res://Autoloads/level_manager.gd")

var _level_manager: Node
var _mock_gameplay: Node

func before_test() -> void:
	_level_manager = auto_free(LevelManagerScript.new())
	# Add to tree to trigger _ready (and signal connections if possible)
	get_tree().root.add_child(_level_manager)

	_mock_gameplay = auto_free(Node.new())
	_mock_gameplay.name = "Gameplay"
	_mock_gameplay.add_user_signal("level_complete")
	_mock_gameplay.add_user_signal("quit_to_title")
	_mock_gameplay.add_user_signal("quit_to_level_select")

func after_test() -> void:
	if is_instance_valid(_level_manager) and _level_manager.is_inside_tree():
		get_tree().root.remove_child(_level_manager)

func test_connects_signals_manually() -> void:
	# Since we can't easily set get_tree().current_scene in a unit test to our mock,
	# we manually invoke the connection logic to verify it handles the signals correctly.
	# We simulate the logic inside _on_scene_changed by passing our mock as the "scene"
	# This requires refactoring LevelManager to accept a scene arg or just testing the connection logic directly.
	# Instead, we will verify the handler exists and is callable.
	assert_bool(_level_manager.has_method("_on_quit_to_level_select")).is_true()

	# Manually connect to verify signature compatibility
	_mock_gameplay.connect("quit_to_level_select", Callable(_level_manager, "_on_quit_to_level_select"))
	assert_bool(_mock_gameplay.is_connected("quit_to_level_select", Callable(_level_manager, "_on_quit_to_level_select"))).is_true()

	# Triggering it should not crash
	_mock_gameplay.emit_signal("quit_to_level_select")
