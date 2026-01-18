extends GdUnitTestSuite

var _unit_manager: UnitManager
var _unit1: Unit
var _unit2: Unit
var _unit3: Unit

func before() -> void:
	_unit_manager = auto_free(UnitManager.new())
	_unit1 = auto_free(Unit.new())
	_unit1.unit_name = "Unit1"
	_unit2 = auto_free(Unit.new())
	_unit2.unit_name = "Unit2"
	_unit3 = auto_free(Unit.new())
	_unit3.unit_name = "Unit3"

func test_get_units() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)

	var units = _unit_manager.get_units()

	assert_int(units.size()).is_equal(2)
	assert_object(units[0]).is_equal(_unit1)
	assert_object(units[1]).is_equal(_unit2)

func test_remove_unit() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)

	_unit_manager.remove_unit(_unit1)

	var units = _unit_manager.get_units()
	assert_int(units.size()).is_equal(1)
	assert_object(units[0]).is_equal(_unit2)

func test_remove_unit_not_found() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	var initial_count = _unit_manager.get_unit_count()

	_unit_manager.remove_unit(_unit2)

	assert_int(_unit_manager.get_unit_count()).is_equal(initial_count)

func test_get_selected_unit() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)

	var selected = _unit_manager.get_selected_unit()

	assert_object(selected).is_equal(_unit1)

func test_get_selected_unit_none() -> void:
	var selected = _unit_manager.get_selected_unit()

	assert_object(selected).is_null()

func test_get_unit_index_by_iterating() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(_unit3, Vector2i(2, 2), true)

	var units = _unit_manager.get_units()

	assert_int(units.find(_unit1)).is_equal(0)
	assert_int(units.find(_unit2)).is_equal(1)
	assert_int(units.find(_unit3)).is_equal(2)

func test_remove_unit_adjusts_selection() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(_unit3, Vector2i(2, 2), true)

	# Remove last unit - should not affect selection
	_unit_manager.remove_unit(_unit3)
	assert_int(_unit_manager.get_selected_index()).is_equal(0)

	# Remove first unit - selection should shift
	_unit_manager.remove_unit(_unit1)
	assert_int(_unit_manager.get_selected_index()).is_equal(0)
	assert_object(_unit_manager.get_selected_unit()).is_equal(_unit2)

func test_remove_unit_from_middle() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)
	_unit_manager.add_unit(_unit3, Vector2i(2, 2), true)

	# Remove _unit2 (middle unit, before selected)
	_unit_manager.remove_unit(_unit2)

	# _unit1 should still be selected at index 0
	assert_int(_unit_manager.get_selected_index()).is_equal(0)
	assert_object(_unit_manager.get_selected_unit()).is_equal(_unit1)

func test_get_unit_index() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)

	assert_int(_unit_manager.get_unit_index(_unit1)).is_equal(0)
	assert_int(_unit_manager.get_unit_index(_unit2)).is_equal(1)
	assert_int(_unit_manager.get_unit_index(_unit3)).is_equal(-1)
