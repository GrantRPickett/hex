extends GdUnitTestSuite

const LocationDetailsPanelScene := preload("res://GUI/location_details_panel.tscn")

func test_location_details_panel_displays_dictionary_payload() -> void:
	var panel: LocationDetailsPanel = auto_free(LocationDetailsPanelScene.instantiate())
	get_tree().root.add_child(panel)
	await panel.ready
	var payload := {
		"title": "Harvest Oasis",
		"description": "Collect water",
		"player_progress": 2,
		"required_amount": 5,
		"completed": false
	}
	panel.update_details(payload)
	assert_bool(panel.visible).is_true()
	assert_str(panel._location_name_label.text).contains("Harvest Oasis")
	assert_str(panel._location_status_label.text).contains("2/5")
