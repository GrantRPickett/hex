extends GdUnitTestSuite

const HUDComponentFactory := preload("res://GUI/HUD/hud_component_factory.gd")
const FilePaths := preload("res://Autoloads/file_paths.gd")

func test_create_margin_container_adds_layout_manager() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	assert_object(margin).is_not_null()
	assert_that(margin.name).is_equal("HUDMarginContainer")
	assert_that(parent.get_child_count()).is_equal(1)
	var layout := margin.get_node("LayoutManager")
	assert_object(layout).is_not_null()

func test_create_layout_containers_returns_expected_nodes() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	var containers := HUDComponentFactory._create_layout_containers(margin)
	var required := ["top_left", "top_right", "bottom_left", "bottom_right", "center_left", "center_right", "top_center", "bottom_center"]
	for key in required:
		assert_bool(containers.has(key)).is_true()
		var node: Node = containers[key]
		assert_object(node).is_not_null()
		assert_object(node.get_parent()).is_same(margin)

func test_populate_components_instantiates_panels() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	var containers := HUDComponentFactory._create_layout_containers(margin)
	var components := HUDComponentFactory.Components.new()
	HUDComponentFactory._populate_components(components, containers)
	assert_object(components.actions_panel).is_not_null()
	assert_object(components.auto_battle_button).is_not_null()
	assert_object(components.morale_panel).is_not_null()
	assert_object(components.actions_panel.get_parent()).is_same(containers["top_center"])
	assert_object(components.morale_panel.get_parent()).is_same(containers["bottom_center"])
func test_config_box_container_sets_properties() -> void:
	var box := VBoxContainer.new()
	var spec := {"name": "TestBox", "preset": Control.PRESET_TOP_LEFT, "h_flag": Control.SIZE_EXPAND_FILL, "v_flag": Control.SIZE_SHRINK_BEGIN, "alignment": BoxContainer.ALIGNMENT_CENTER, "separator": true}
	HUDComponentFactory._config_box_container(box, spec)
	assert_str(box.name).is_equal("TestBox")
	assert_int(box.alignment).is_equal(BoxContainer.ALIGNMENT_CENTER)

func test_instantiate_panel_adds_child() -> void:
	var parent := VBoxContainer.new()
	var panel := HUDComponentFactory._instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, parent, "TestPanel")
	assert_object(panel).is_not_null()
	assert_str(panel.name).is_equal("TestPanel")
	assert_int(parent.get_child_count()).is_equal(1)

func test_populate_left_columns_instantiates_panels() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	var containers := HUDComponentFactory._create_layout_containers(margin)
	var components := HUDComponentFactory.Components.new()
	HUDComponentFactory._populate_left_columns(components, containers)
	assert_object(components.locations_list).is_not_null()
	assert_object(components.unit_details).is_not_null()

func test_populate_right_columns_creates_buttons() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	var containers := HUDComponentFactory._create_layout_containers(margin)
	var components := HUDComponentFactory.Components.new()
	HUDComponentFactory._populate_right_columns(components, containers)
	assert_object(components.pause_button).is_not_null()
	assert_object(components.weather_panel).is_not_null()

func test_populate_center_sections_sets_components() -> void:
	var parent := Control.new()
	var margin := HUDComponentFactory._create_margin_container(parent)
	var containers := HUDComponentFactory._create_layout_containers(margin)
	var components := HUDComponentFactory.Components.new()
	HUDComponentFactory._populate_center_sections(components, containers)
	assert_object(components.actions_panel).is_not_null()
	assert_object(components.morale_panel).is_not_null()

func test_create_button_applies_spec() -> void:
	var parent := HBoxContainer.new()
	var button := HUDComponentFactory._create_button(parent, {"name": "SpecButton", "text": "Play", "tooltip": "Tip", "size": Vector2(50, 20), "toggle": true})
	assert_str(button.name).is_equal("SpecButton")
	assert_bool(button.toggle_mode).is_true()
