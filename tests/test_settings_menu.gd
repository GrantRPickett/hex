extends GdUnitTestSuite

const SETTINGS_MENU_PATH := "res://Menus/settings_menu.tscn"
const TestUtils := preload("res://tests/base_test_suite.gd")

var _runner: GdUnitSceneRunner
var _audio_bus_controller: Node
var _game_config: Node
var _display_settings: Node

const AUTOLOADS_TO_MANAGE = {
	"AudioBusController": "res://Autoloads/audio_bus_controller.gd",
	"GameConfig": "res://Autoloads/game_config.gd",
	"DisplaySettings": "res://Autoloads/display_settings.gd",
	"LocaleService": "res://Autoloads/locale_service.gd",
	"DifficultyService": "res://Autoloads/difficulty_service.gd"
}

func before_test() -> void:
	var instances = await TestUtils.setup_autoloads(get_tree(), AUTOLOADS_TO_MANAGE)
	_audio_bus_controller = instances["AudioBusController"]
	_game_config = instances["GameConfig"]
	_display_settings = instances["DisplaySettings"]

	_runner = scene_runner(SETTINGS_MENU_PATH)
	await _runner.simulate_frames(1)

func after_test() -> void:
	_runner = null
	await TestUtils.teardown_autoloads(get_tree())

func test_tab_container_exists() -> void:
	var tabs: TabContainer = _runner.find_child("TabContainer", true, false)
	assert_that(tabs).is_not_null()
	assert_that(tabs.get_tab_count()).is_equal(4)
	# Tab 2 should be Language & Flow
	assert_that(tabs.get_tab_title(2)).is_equal(tr("settings.tab.language_flow"))

func test_volume_slider_updates_audio_and_config() -> void:
	# Find the dynamically created slider in the Audio tab
	var vbox = _runner.find_child("AudioVBox", true, false)
	var slider: HSlider = null
	for child in vbox.get_children():
		if child is HBoxContainer:
			slider = child.find_child("Slider", true, false)
			if slider: break
	
	assert_that(slider).is_not_null()

	slider.value = -10.0
	slider.value_changed.emit(-10.0)

	assert_that(_audio_bus_controller.get_bus_volume_db("Master")).is_equal(-10.0)
	assert_that(_game_config.get_value("audio/master_db")).is_equal(-10.0)

func test_animation_speed_in_graphics_tab() -> void:
	var graphics_vbox = _runner.find_child("GraphicsVBox", true, false)
	var anim_speed = graphics_vbox.find_child("AnimationSpeed", true, false)
	assert_that(anim_speed).is_not_null()

func test_language_selection_in_flow_tab() -> void:
	# LanguageRow is added dynamically to LanguageFlowVBox
	var flow_vbox = _runner.find_child("LanguageFlowVBox", true, false)
	# Trigger setup to ensure it's added
	_runner.scene().setup(_game_config)
	var lang_row = flow_vbox.get_node_or_null("LanguageRow")
	assert_that(lang_row).is_not_null()

func test_orientation_selection_updates_config() -> void:
	var scene = _runner.scene()
	scene._on_orientation_selected(1) # PORTRAIT
	assert_that(_game_config.get_value("display/orientation")).is_equal("portrait")

func test_reset_controls_button_exists() -> void:
	var btn: Button = _runner.find_child("Reset", true, false)
	assert_that(btn).is_not_null()
