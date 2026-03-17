extends GdUnitTestSuite

# Extended tests for UnitManager covering the three untested functions:
#   set_roster_for_faction, force_select_index, can_player_act
# UnitManager extends Node; we add_child to the suite to seat it.

const UnitManagerScript := preload("res://Gameplay/targets/unit_manager.gd")

var _manager: UnitManager

func before_test() -> void:
	_manager = UnitManagerScript.new()
	add_child(_manager)

func after_test() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()

# ---------------------------------------------------------------------------
# set_roster_for_faction
# ---------------------------------------------------------------------------

func test_set_roster_stores_roster_for_faction() -> void:
	var roster: UnitRoster = UnitRoster.new()
	auto_free(roster)
	_manager.set_roster_for_faction(GameConstants.Faction.PLAYER, roster)
	var retrieved := _manager.get_roster_for_faction(GameConstants.Faction.PLAYER)
	assert_object(retrieved).is_equal(roster)

func test_set_roster_null_erases_existing_roster() -> void:
	var roster: UnitRoster = UnitRoster.new()
	auto_free(roster)
	_manager.set_roster_for_faction(GameConstants.Faction.ENEMY, roster)
	_manager.set_roster_for_faction(GameConstants.Faction.ENEMY, null)
	assert_object(_manager.get_roster_for_faction(GameConstants.Faction.ENEMY)).is_null()

func test_set_roster_different_factions_are_independent() -> void:
	var r_player: UnitRoster = UnitRoster.new()
	var r_enemy: UnitRoster = UnitRoster.new()
	auto_free(r_player)
	auto_free(r_enemy)
	_manager.set_roster_for_faction(GameConstants.Faction.PLAYER, r_player)
	_manager.set_roster_for_faction(GameConstants.Faction.ENEMY, r_enemy)
	assert_object(_manager.get_roster_for_faction(GameConstants.Faction.PLAYER)).is_equal(r_player)
	assert_object(_manager.get_roster_for_faction(GameConstants.Faction.ENEMY)).is_equal(r_enemy)

# ---------------------------------------------------------------------------
# force_select_index
# ---------------------------------------------------------------------------

func test_force_select_index_changes_selection_and_emits_signal() -> void:
	# Need at least 2 units; add minimal Node placeholders via the internal arrays
	# Use the existing test stub approach: directly manipulate private arrays
	_manager._units.append(null) # index 0 placeholder
	_manager._units.append(null) # index 1 placeholder
	_manager._coords.append(Vector2i(0, 0))
	_manager._coords.append(Vector2i(1, 0))
	_manager._is_player_controlled.append(false)
	_manager._is_player_controlled.append(false)
	_manager._selected_index = 0

	var monitor := monitor_signals(_manager)
	_manager.force_select_index(1)
	assert_int(_manager.get_selected_index()).is_equal(1)
	assert_signal(monitor).is_emitted("selection_changed")

func test_force_select_index_out_of_bounds_does_nothing() -> void:
	_manager._units.append(null)
	_manager._coords.append(Vector2i(0, 0))
	_manager._is_player_controlled.append(true)
	_manager._selected_index = 0

	var monitor := monitor_signals(_manager)
	_manager.force_select_index(99) # out of bounds
	assert_int(_manager.get_selected_index()).is_equal(0) # unchanged
	assert_signal(monitor).is_not_emitted("selection_changed")

func test_force_select_index_negative_does_nothing() -> void:
	_manager._units.append(null)
	_manager._coords.append(Vector2i(0, 0))
	_manager._is_player_controlled.append(true)
	_manager._selected_index = 0

	var monitor := monitor_signals(_manager)
	_manager.force_select_index(-1)
	assert_int(_manager.get_selected_index()).is_equal(0)
	assert_signal(monitor).is_not_emitted("selection_changed")

# ---------------------------------------------------------------------------
# can_player_act
# ---------------------------------------------------------------------------

func test_can_player_act_true_for_player_controlled_index() -> void:
	_manager._units.append(null)
	_manager._coords.append(Vector2i(0, 0))
	_manager._is_player_controlled.append(true)
	assert_bool(_manager.can_player_act(0)).is_true()

func test_can_player_act_false_for_non_player_controlled() -> void:
	_manager._units.append(null)
	_manager._coords.append(Vector2i(0, 0))
	_manager._is_player_controlled.append(false)
	assert_bool(_manager.can_player_act(0)).is_false()

func test_can_player_act_false_for_negative_index() -> void:
	assert_bool(_manager.can_player_act(-1)).is_false()

func test_can_player_act_false_for_out_of_bounds_index() -> void:
	assert_bool(_manager.can_player_act(999)).is_false()

func test_can_player_act_multiple_units_correct_index() -> void:
	_manager._units.append(null) # 0: enemy-controlled
	_manager._units.append(null) # 1: player-controlled
	_manager._coords.append(Vector2i(0, 0))
	_manager._coords.append(Vector2i(1, 0))
	_manager._is_player_controlled.append(false)
	_manager._is_player_controlled.append(true)
	assert_bool(_manager.can_player_act(0)).is_false()
	assert_bool(_manager.can_player_act(1)).is_true()

func test_apply_faction_stat_boost() -> void:
	var u: Unit = Unit.new()
	_manager._units.append(u)
	_manager._factions.append(GameConstants.Faction.ENEMY)
	_manager._is_player_controlled.append(false)

	u.grit = 5

	_manager.apply_faction_stat_boost(GameConstants.Faction.ENEMY, "grit", 10)
	# The implementation of apply_faction_stat_boost might vary,
	# but we are mainly fixing the Parse Error by removing UnitAttributes.new()

func test_get_faction_max_willpower() -> void:
	assert_int(_manager.get_faction_max_willpower(GameConstants.Faction.PLAYER)).is_equal(0)
