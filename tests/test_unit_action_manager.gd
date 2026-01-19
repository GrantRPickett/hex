extends GdUnitTestSuite

const UnitActionManager = preload("res://Gameplay/unit_action_manager.gd")

func test_unit_action_manager_is_callable() -> void:
	# Verify UnitActionManager class exists and is accessible
	assert_object(UnitActionManager).is_not_null()

func test_is_unit_stuck_called_with_null_unit() -> void:
	# Verify is_unit_stuck returns true for null/invalid unit
	var result = UnitActionManager.is_unit_stuck(null, null, null)
	assert_bool(result).is_true()

func test_get_available_actions_called() -> void:
	# Verify get_available_actions is callable (returns empty array for null unit)
	var result = UnitActionManager.get_available_actions(null, null, null)
	assert_array(result).is_empty()
