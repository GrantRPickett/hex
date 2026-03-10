extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
var _game_config: Node

func before_test() -> void:
	_game_config = await HexTestUtils.ensure_manager(get_tree(), "GameConfig", "res://Autoloads/game_config.gd")

func after_test() -> void:
	if is_instance_valid(_game_config):
		_game_config.queue_free()
	await get_tree().process_frame

func test_autoload_singletons_present() -> void:
	var root := get_tree().root
	# Verify core autoloads are present as singletons under /root
	assert_that(root.has_node("ControlSettings")).is_true()
	assert_that(root.has_node("GameConfig")).is_true()
	assert_that(root.has_node("SceneTransition")).is_true()
	assert_that(root.has_node("InputMapper")).is_true()
	assert_that(root.has_node("DisplaySettings")).is_true()
	assert_that(root.has_node("AudioBusController")).is_true()
	assert_that(root.has_node("EventBus")).is_true()

var _last_config_path := ""
var _last_config_value = null

func _on_config_changed(path, value) -> void:
	_last_config_path = String(path)
	_last_config_value = value

func test_game_config_emits_config_changed() -> void:
	_last_config_path = ""
	_last_config_value = null
	_game_config.config_changed.connect(Callable(self , "_on_config_changed"))
	_game_config.set_value("controls/invert_y", true)
	_game_config.config_changed.disconnect(Callable(self , "_on_config_changed"))
	assert_that(_last_config_path).is_equal("controls/invert_y")
	assert_that(_last_config_value).is_true()
