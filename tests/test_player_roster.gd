extends GdUnitTestSuite

var _roster: PlayerRoster
var _unit_scene1: PackedScene
var _unit_scene2: PackedScene

func before() -> void:
	_roster = auto_free(PlayerRoster.new())
	_roster.units = []  # Ensure units array is cleared for each test

	# Disable permadeath in SaveManager to ensure roster is cleanly replaced each test
	SaveManager.set_value("permadeath", true)

	# Create mock unit scenes
	_unit_scene1 = PackedScene.new()
	_unit_scene2 = PackedScene.new()

func test_get_units_empty() -> void:
	_roster.units = []

	var units = _roster.get_units()

	assert_int(units.size()).is_equal(0)

func test_get_units_returns_array() -> void:
	var units = _roster.get_units()

	assert_int(units.size()).is_equal(0)

func test_update_roster_empty() -> void:
	var active_units: Array[Unit] = []

	_roster.update_roster(active_units)

	# After updating with empty active units, roster should be empty
	assert_int(_roster.units.size()).is_equal(0)

func test_update_roster_with_units() -> void:
	var unit = auto_free(Unit.new())
	unit.unit_name = "TestUnit"
	var active_units: Array[Unit] = [unit]

	_roster.update_roster(active_units)

	# Roster should now contain one scene
	assert_int(_roster.units.size()).is_equal(1)

func test_update_roster_multiple_units() -> void:
	var unit1 = auto_free(Unit.new())
	unit1.unit_name = "Unit1"
	var unit2 = auto_free(Unit.new())
	unit2.unit_name = "Unit2"
	var unit3 = auto_free(Unit.new())
	unit3.unit_name = "Unit3"

	var active_units: Array[Unit] = [unit1, unit2, unit3]

	_roster.update_roster(active_units)

	assert_int(_roster.units.size()).is_equal(3)

func test_update_roster_handles_null_units() -> void:
	var unit = auto_free(Unit.new())
	unit.unit_name = "TestUnit"
	var active_units: Array[Unit] = [unit, null, unit]

	_roster.update_roster(active_units)

	# Should only add non-null units
	assert_int(_roster.units.size()).is_equal(2)
