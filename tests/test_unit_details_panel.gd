extends GdUnitTestSuite

const UnitDetailsPanelScene := preload("res://GUI/unit_details_panel.tscn")
const Unit := preload("res://Gameplay/unit.gd")

func _make_unit_with_attributes() -> Unit:
	var unit: Unit = auto_free(Unit.new())
	var scene_root := get_tree().root
	scene_root.add_child(unit)
	unit._ready()
	unit.unit_name = "Scout"
	unit.max_willpower = 10
	unit.willpower = 8
	var attrs = unit.get_attributes()
	if attrs:
		attrs.set_base_attribute("grit", 5)
		attrs.set_base_attribute("flow", 4)
	return unit

func test_unit_details_panel_lists_attributes() -> void:
	var panel: UnitDetailsPanel = auto_free(UnitDetailsPanelScene.instantiate())
	get_tree().root.add_child(panel)
	await panel.ready
	var unit := _make_unit_with_attributes()
	panel.update_details(unit, null, null)
	var attr_label: Label = panel._vbox.get_node("AttributesLabel")
	assert_str(attr_label.text).contains("Grit: 5")
