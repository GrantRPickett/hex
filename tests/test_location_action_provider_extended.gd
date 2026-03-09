extends GdUnitTestSuite

const LocationActionProviderScript = preload("res://Gameplay/targets/location_action_provider.gd")

func test_location_action_provider_append_location_action() -> void:
	var provider = auto_free(LocationActionProviderScript.new())
	var actions = []

	# Mock requirements
	var action = {
		"type": "explore",
		"location": "town",
		"label": "Explore town",
		"available": true,
		"effort_cost": 1
	}
	provider.append_location_action(actions, action)
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0]["type"]).is_equal("explore")
