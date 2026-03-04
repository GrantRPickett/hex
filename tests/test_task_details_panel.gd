extends GdUnitTestSuite

const LocationDetailsPanelScene := preload("res://GUI/location_details_panel.tscn")

func test_location_details_panel_displays_dictionary_payload() -> void:
	var panel: LocationDetailsPanel = auto_free(LocationDetailsPanelScene.instantiate())
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	var payload := {
		"name": "Harvest Oasis",
		"description": "Collect water",
		"task": {
			"title": "Gather water",
			"current_effort": 2,
			"effort_required": 5,
		},
	}
	panel.update_details(payload)
	assert_bool(panel.visible).is_true()
	assert_str(panel._location_name_label.text).contains("Harvest Oasis")
	assert_str(panel._task_label.text).contains("2/5")
