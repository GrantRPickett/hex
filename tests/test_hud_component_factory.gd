extends GdUnitTestSuite

const HUDComponentFactory := preload("res://GUI/HUD/hud_component_factory.gd")
const FilePaths := preload("res://Autoloads/file_paths.gd")

func test_create_components_landscape() -> void:
	var parent: Control = auto_free(Control.new())
	var components: HUDComponentFactory.Components = HUDComponentFactory.create_components(parent, false)
	
	assert_object(components).is_not_null()
	assert_object(components.margin_container).is_not_null()
	assert_str(components.margin_container.name).is_equal("LandscapeHUD")
	
	# Verify key components are instantiated
	assert_object(components.actions_panel).is_not_null()
	assert_object(components.locations_list).is_not_null()
	assert_object(components.unit_details).is_not_null()
	
	# Verify landscape-specific parent (LeftColumn is a child of ColumnContainer)
	var left_column: Node = components.margin_container.get_node("%LeftColumn")
	assert_object(components.locations_list.get_parent()).is_same(left_column)

func test_create_components_portrait() -> void:
	var parent: Control = auto_free(Control.new())
	var components: HUDComponentFactory.Components = HUDComponentFactory.create_components(parent, true)
	
	assert_object(components).is_not_null()
	assert_object(components.margin_container).is_not_null()
	assert_str(components.margin_container.name).is_equal("PortraitHUD")
	
	# Verify key components are instantiated
	assert_object(components.actions_panel).is_not_null()
	assert_object(components.locations_list).is_not_null()
	
	# Verify portrait-specific parent (LocationsList is in LocationsTab)
	var locations_tab: Node = components.margin_container.get_node("%LocationsTab")
	assert_object(components.locations_list.get_parent()).is_same(locations_tab)
	
	# Verify buttons are in TopButtons anchor
	var top_buttons: Node = components.margin_container.get_node("%TopButtons")
	assert_object(components.auto_battle_button.get_parent().get_parent()).is_same(top_buttons)

func test_instantiate_panel_adds_child() -> void:
	var parent: VBoxContainer = auto_free(VBoxContainer.new())
	var panel: Control = HUDComponentFactory._instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, parent, "TestPanel")
	assert_object(panel).is_not_null()
	assert_str(panel.name).is_equal("TestPanel")
	assert_int(parent.get_child_count()).is_equal(1)

func test_create_button_applies_spec() -> void:
	var parent: HBoxContainer = auto_free(HBoxContainer.new())
	var button: Button = HUDComponentFactory._create_button(parent, {
		"name": "SpecButton", 
		"text": "Play", 
		"tooltip": "Tip", 
		"size": Vector2(50, 20), 
		"toggle": true
	})
	assert_str(button.name).is_equal("SpecButton")
	assert_bool(button.toggle_mode).is_true()
	assert_str(button.text).is_equal("Play")
