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

func test_format_action_label_reports_counts() -> void:
	var label := UnitActionManager._format_action_label("Attack", 2, 3)
	assert_str(label).contains("2 adjacent")
	assert_str(label).contains("3 reachable")

func test_has_reachable_adjacent_respects_distance() -> void:
	var coords := [Vector2i(0, 1), Vector2i(2, 2)]
	var result := UnitActionManager._has_reachable_adjacent(coords, Vector2i(0, 0), TileSet.TILE_OFFSET_AXIS_VERTICAL, 1.5)
	assert_bool(result).is_true()

func test_can_reach_coord_detects_exact_tile() -> void:
	var coords := [Vector2i(5, 5), Vector2i(3, 1)]
	assert_bool(UnitActionManager._can_reach_coord(coords, Vector2i(3, 1))).is_true()
