extends GdUnitTestSuite

func test_autoload_singletons_present() -> void:
	var root := get_tree().root
	# Verify core autoloads are present as singletons under /root
	assert_that(root.has_node("ControlSettings")).is_true()
	assert_that(root.has_node("GameConfig")).is_true()
	assert_that(root.has_node("SceneTransition")).is_true()
	assert_that(root.has_node("InputMapper")).is_true()
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
	GameConfig.config_changed.connect(Callable(self, "_on_config_changed"))
	GameConfig.set_value("controls/invert_y", true)
	GameConfig.config_changed.disconnect(Callable(self, "_on_config_changed"))
	assert_that(_last_config_path).is_equal("controls/invert_y")
	assert_that(_last_config_value).is_true()
