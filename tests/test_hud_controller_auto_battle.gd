extends GdUnitTestSuite

const HUDControllerScript := preload("res://GUI/HUD/hud_controller.gd")
const HUDComponentFactory := preload("res://GUI/HUD/hud_component_factory.gd")
const ActionsPanelScene := preload("res://GUI/actions_panel.tscn")

var _hud: Hud
var _controller: HUDController
var _components: HUDComponentFactory.Components

func before() -> void:
	_hud = auto_free(Hud.new())
	get_tree().root.add_child(_hud)
	_controller = auto_free(HUDControllerScript.new())
	get_tree().root.add_child(_controller)
	_components = HUDComponentFactory.Components.new()
	_components.actions_panel = auto_free(ActionsPanelScene.instantiate())
	_hud.add_child(_components.actions_panel)
	_components.auto_battle_button = Button.new()
	_hud.add_child(_components.auto_battle_button)
	# Inject components directly since setup() now requires a full GameState
	_controller._components = _components
	_controller._connect_components()

func test_set_auto_battle_state_updates_button_and_panel() -> void:
	await get_tree().process_frame
	_controller.set_auto_battle_state(true)
	assert_bool(_components.auto_battle_button.button_pressed).is_true()
	assert_bool(_components.actions_panel.hint_label.visible).is_false()
	_controller.set_auto_battle_state(false)
	assert_bool(_components.auto_battle_button.button_pressed).is_false()
	assert_bool(_components.actions_panel.hint_label.visible).is_true()

func test_auto_battle_button_emits_toggle_signal() -> void:
	await get_tree().process_frame
	var toggles: Array[bool] = []
	_controller.auto_battle_toggle_requested.connect(func(enabled: bool): toggles.append(enabled))
	_components.auto_battle_button.button_pressed = false
	_components.auto_battle_button.emit_signal("toggled", true)
	await get_tree().process_frame
	assert_array(toggles).has_size(1)
	assert_bool(toggles[0]).is_true()
