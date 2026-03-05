extends GdUnitTestSuite

const HUDComponentFactory := preload("res://GUI/HUD/hud_component_factory.gd")

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
