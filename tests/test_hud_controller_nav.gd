extends GdUnitTestSuite

const HUDController := preload("res://Gameplay/hud_controller.gd")
const HUDComponentFactory := preload("res://Gameplay/hud_component_factory.gd")

class FakePanel extends Control:
	var enable_calls := 0
	var disable_calls := 0

	func enable_navigation_mode() -> void:
		enable_calls += 1

	func disable_navigation_mode() -> void:
		disable_calls += 1

func test_set_ui_navigation_mode_delegates_to_actions_panel() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	var components := HUDComponentFactory.Components.new()
	var panel := FakePanel.new()
	components.actions_panel = panel
	controller._components = components
	controller.set_ui_navigation_mode(true)
	assert_int(panel.enable_calls).is_equal(1)
	controller.set_ui_navigation_mode(false)
	assert_int(panel.disable_calls).is_equal(1)

func test_safe_zone_mode_hides_combat_panels() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	var components := HUDComponentFactory.Components.new()
	components.actions_panel = Control.new()
	components.combat_preview = Control.new()
	components.morale_panel = Control.new()
	controller._components = components
	controller.set_safe_zone_mode(true)
	assert_bool(components.actions_panel.visible).is_false()
	assert_bool(components.combat_preview.visible).is_false()
	assert_bool(components.morale_panel.visible).is_false()

func test_safe_zone_mode_restores_panels_when_disabled() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	var components := HUDComponentFactory.Components.new()
	components.actions_panel = Control.new()
	components.combat_preview = Control.new()
	components.morale_panel = Control.new()
	controller._components = components
	controller.set_safe_zone_mode(true)
	controller.set_safe_zone_mode(false)
	assert_bool(components.actions_panel.visible).is_true()
	assert_bool(components.combat_preview.visible).is_true()
	assert_bool(components.morale_panel.visible).is_true()
