extends GdUnitTestSuite

const GenericUnitScene := preload("res://Gameplay/generic_unit.tscn")
const RosterPersistence := preload("res://Gameplay/roster_persistence.gd")
const InventoryItem := preload("res://Gameplay/inventory_item.gd")

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

func test_update_roster_preserves_missing_units_when_permadeath_disabled() -> void:
	var unit_a = auto_free(GenericUnitScene.instantiate() as Unit)
	unit_a.unit_name = "UnitA"
	var unit_b = auto_free(GenericUnitScene.instantiate() as Unit)
	unit_b.unit_name = "UnitB"

	var entry_a = RosterPersistence.unit_to_entry(unit_a)
	var entry_b = RosterPersistence.unit_to_entry(unit_b)

	_roster.roster_entries = [entry_a, entry_b]
	_roster.units = [
		RosterPersistence.entry_to_scene(entry_a),
		RosterPersistence.entry_to_scene(entry_b)
	]

	var active_units: Array[Unit] = [unit_a]

	_roster.update_roster(active_units, false)

	assert_int(_roster.roster_entries.size()).is_equal(2)
	var names: Array = []
	for entry in _roster.roster_entries:
		names.append(entry.get("unit_name", ""))

	assert_bool(names.has("UnitA")).is_true()
	assert_bool(names.has("UnitB")).is_true()

func test_add_to_stash_and_clear() -> void:
	var item := InventoryItem.new()
	item.item_name = "Potion"
	_roster.add_to_stash([item])
	assert_int(_roster.stash_items.size()).is_equal(1)
	assert_str(_roster.stash_items[0].item_name).is_equal("Potion")
	assert_bool(_roster.stash_items[0] == item).is_false()
	_roster.clear_stash()
	assert_int(_roster.stash_items.size()).is_equal(0)

func test_set_remaining_goal_titles_tracks_value() -> void:
	var titles := PackedStringArray(["GoalA", "GoalB"])
	_roster.set_remaining_goal_titles(titles)
	var stored := _roster.get_remaining_goal_titles()
	assert_int(stored.size()).is_equal(2)
	assert_str(stored[0]).is_equal("GoalA")
	assert_str(stored[1]).is_equal("GoalB")
	assert_bool(stored == titles).is_false()
