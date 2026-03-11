extends GdUnitTestSuite

const HUDControllerClass := preload("res://GUI/HUD/hud_controller.gd")
const HUDComponentFactoryClass := preload("res://GUI/HUD/hud_component_factory.gd")
const ActionsPanelClass := preload("res://GUI/actions_panel.gd")
const CombatPreviewPanelClass := preload("res://GUI/combat_preview_panel.gd")
const MoralePanelClass := preload("res://GUI/morale_panel.gd")

class FakePanel extends ActionsPanelClass:
	var enable_calls := 0
	var disable_calls := 0

	func enable_navigation_mode() -> void:
		enable_calls += 1

	func disable_navigation_mode() -> void:
		disable_calls += 1

func test_set_ui_navigation_mode_delegates_to_actions_panel() -> void:
	var controller: HUDController = auto_free(HUDControllerClass.new())
	var components := HUDComponentFactoryClass.Components.new()
	var panel := FakePanel.new()
	components.actions_panel = panel
	controller._components = components
	controller.set_ui_navigation_mode(true)
	assert_int(panel.enable_calls).is_equal(1)
	controller.set_ui_navigation_mode(false)
	assert_int(panel.disable_calls).is_equal(1)

func test_safe_zone_mode_hides_combat_panels() -> void:
	var controller: HUDController = auto_free(HUDControllerClass.new())
	var components := HUDComponentFactoryClass.Components.new()
	components.actions_panel = auto_free(ActionsPanelClass.new())
	components.combat_preview = auto_free(CombatPreviewPanelClass.new())
	components.morale_panel = auto_free(MoralePanelClass.new())
	controller._components = components
	controller.set_safe_zone_mode(true)
	# HUDController._apply_safe_zone_visibility sets actions_panel to true always
	assert_bool(components.actions_panel.visible).is_true()
	assert_bool(components.combat_preview.visible).is_false()
	assert_bool(components.morale_panel.visible).is_false()

func test_safe_zone_mode_restores_panels_when_disabled() -> void:
	var controller: HUDController = auto_free(HUDControllerClass.new())
	var components := HUDComponentFactoryClass.Components.new()
	components.actions_panel = auto_free(ActionsPanelClass.new())
	components.combat_preview = auto_free(CombatPreviewPanelClass.new())
	components.morale_panel = auto_free(MoralePanelClass.new())
	controller._components = components
	controller.set_safe_zone_mode(true)
	controller.set_safe_zone_mode(false)
	assert_bool(components.actions_panel.visible).is_true()
	assert_bool(components.combat_preview.visible).is_true()
	assert_bool(components.morale_panel.visible).is_true()
