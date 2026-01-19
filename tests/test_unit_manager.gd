extends GdUnitTestSuite

var _unit_manager: UnitManager

func before() -> void:
	_unit_manager = auto_free(UnitManager.new())

func _make_unit(name: String) -> Unit:
	var unit = auto_free(Unit.new())
	unit.unit_name = name
	return unit

func test_get_units() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)

	var units = _unit_manager.get_units()

	assert_int(units.size()).is_equal(2)
	assert_object(units[0]).is_equal(unit1)
	assert_object(units[1]).is_equal(unit2)

func test_remove_unit() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)

	_unit_manager.remove_unit(unit1)

	var units = _unit_manager.get_units()
	assert_int(units.size()).is_equal(1)
	assert_object(units[0]).is_equal(unit2)

func test_remove_unit_not_found() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	var initial_count = _unit_manager.get_unit_count()

	_unit_manager.remove_unit(unit2)

	assert_int(_unit_manager.get_unit_count()).is_equal(initial_count)

func test_get_selected_unit() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)

	var selected = _unit_manager.get_selected_unit()

	assert_object(selected).is_equal(unit1)

func test_get_selected_unit_none() -> void:
	var selected = _unit_manager.get_selected_unit()

	assert_object(selected).is_null()

func test_get_unit_index_by_iterating() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	var unit3 = _make_unit("Unit3")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(unit3, Vector2i(2, 2), true)

	var units = _unit_manager.get_units()

	assert_int(units.find(unit1)).is_equal(0)
	assert_int(units.find(unit2)).is_equal(1)
	assert_int(units.find(unit3)).is_equal(2)

func test_remove_unit_adjusts_selection() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	var unit3 = _make_unit("Unit3")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(unit3, Vector2i(2, 2), true)

	# Remove last unit - should not affect selection
	_unit_manager.remove_unit(unit3)
	assert_int(_unit_manager.get_selected_index()).is_equal(0)

	# Remove first unit - selection should shift
	_unit_manager.remove_unit(unit1)
	assert_int(_unit_manager.get_selected_index()).is_equal(0)
	assert_object(_unit_manager.get_selected_unit()).is_equal(unit2)

func test_remove_unit_from_middle() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	var unit3 = _make_unit("Unit3")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(unit3, Vector2i(2, 2), true)

	# Remove unit2 (middle unit, before selected)
	_unit_manager.remove_unit(unit2)

	# unit1 should still be selected at index 0
	assert_int(_unit_manager.get_selected_index()).is_equal(0)
	assert_object(_unit_manager.get_selected_unit()).is_equal(unit1)

func test_get_unit_index() -> void:
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	var unit3 = _make_unit("Unit3")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), false)

	assert_int(_unit_manager.get_unit_index(unit1)).is_equal(0)
	assert_int(_unit_manager.get_unit_index(unit2)).is_equal(1)
	assert_int(_unit_manager.get_unit_index(unit3)).is_equal(-1)
# ============================================================================
# Gameplay/unit_manager.gd: get_selected_sprite
# ============================================================================
func test_unit_manager_get_selected_sprite() -> void:
	# Given
	var unit1 = _make_unit("Unit1")
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(unit2, Vector2i(1, 1), true)

	_unit_manager.select_index(1)

	# When
	var selected_sprite = _unit_manager.get_selected_sprite()

	# Then
	assert_object(selected_sprite).is_equal(unit2)

# ============================================================================
# Gameplay/unit_manager.gd: set_coord
# ============================================================================
func test_unit_manager_set_coord() -> void:
	# Given
	var initial_coord = Vector2i(0, 0)
	var new_coord = Vector2i(1, 1)
	var unit_index = 0

	var unit1 = _make_unit("Unit1")
	_unit_manager.add_unit(unit1, initial_coord, true)

	# When
	_unit_manager.set_coord(unit_index, new_coord)

	# Then
	assert_that(_unit_manager.get_coord(unit_index)).is_equal(new_coord)

# ============================================================================
# Gameplay/unit_manager.gd: set_player_controlled
# ============================================================================
func test_unit_manager_set_player_controlled() -> void:
	# Given
	var coord1 = Vector2i(0, 0)
	var unit_index = 0

	var unit1 = _make_unit("Unit1")
	_unit_manager.add_unit(unit1, coord1, false)

	# When - set to player controlled
	_unit_manager.set_player_controlled(unit_index, true)

	# Then
	assert_bool(_unit_manager.is_player_controlled(unit_index)).is_true()

	# When - set to not player controlled
	_unit_manager.set_player_controlled(unit_index, false)

	# Then
	assert_bool(_unit_manager.is_player_controlled(unit_index)).is_false()

# ============================================================================
# Gameplay/unit_manager.gd: set_goal_reached
# ============================================================================
func test_unit_manager_set_goal_reached() -> void:
	# Given
	var coord1 = Vector2i(0, 0)
	var unit_index = 0

	var unit1 = _make_unit("Unit1")
	_unit_manager.add_unit(unit1, coord1, true)

	# When - set goal reached to true
	_unit_manager.set_goal_reached(unit_index, true)

	# Then
	assert_bool(_unit_manager.is_goal_reached(unit_index)).is_true()

	# When - set goal reached to false
	_unit_manager.set_goal_reached(unit_index, false)

	# Then
	assert_bool(_unit_manager.is_goal_reached(unit_index)).is_false()

# ============================================================================
# Gameplay/unit_manager.gd: are_all_goals_reached
# ============================================================================
func test_unit_manager_are_all_goals_reached() -> void:
	# Scenario 1: No units
	assert_bool(_unit_manager.are_all_goals_reached()).is_false()

	# Scenario 2: One player unit, goal not reached
	var unit1 = _make_unit("Unit1")
	_unit_manager.add_unit(unit1, Vector2i(0, 0), true)
	_unit_manager.set_goal_reached(0, false)
	assert_bool(_unit_manager.are_all_goals_reached()).is_false()

	# Scenario 3: One player unit, goal reached
	_unit_manager.set_goal_reached(0, true)
	assert_bool(_unit_manager.are_all_goals_reached()).is_true()

	# Scenario 4: Two player units, one goal reached, one not
	var unit2 = _make_unit("Unit2")
	_unit_manager.add_unit(unit2, Vector2i(1, 1), true)
	_unit_manager.set_goal_reached(0, true)
	_unit_manager.set_goal_reached(1, false)
	assert_bool(_unit_manager.are_all_goals_reached()).is_false()

	# Scenario 5: Two player units, both goals reached
	_unit_manager.set_goal_reached(0, true)
	_unit_manager.set_goal_reached(1, true)
	assert_bool(_unit_manager.are_all_goals_reached()).is_true()

	# Scenario 6: Mixed player and enemy units, player goals reached
	var unit3 = _make_unit("Unit3")
	_unit_manager.add_unit(unit3, Vector2i(2, 2), false)
	_unit_manager.set_goal_reached(0, true)
	_unit_manager.set_goal_reached(1, true)
	# The enemy unit's goal status doesn't matter for this function
	assert_bool(_unit_manager.are_all_goals_reached()).is_true()

	# Scenario 7: No player units
	_unit_manager.reset()
	var unit3_2 = _make_unit("Unit3")
	_unit_manager.add_unit(unit3_2, Vector2i(0, 0), false)
	assert_bool(_unit_manager.are_all_goals_reached()).is_false()