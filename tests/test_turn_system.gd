extends GdUnitTestSuite

const TurnSystem := preload("res://Gameplay/turn_system.gd")
const SIDE_PLAYER := 0
const SIDE_OTHER := 1

func test_configure_initializes_roster_and_active_side() -> void:
	var system: TurnSystem = auto_free(TurnSystem.new())
	system.configure([0, 2], [5])
	assert_int(system.get_active_side()).is_equal(SIDE_PLAYER)
	var player_available: Array = system.get_available_indexes(SIDE_PLAYER)
	assert_that(player_available).contains(0)
	assert_that(player_available).contains(2)
	assert_bool(system.can_unit_act(0)).is_true()
	assert_bool(system.can_unit_act(5)).is_true()

func test_mark_unit_acted_alternates_and_resets_round() -> void:
	var system: TurnSystem = auto_free(TurnSystem.new())
	system.configure([0, 1, 2], [3])
	system.set_initial_side(SIDE_PLAYER)
	assert_int(system.get_active_side()).is_equal(SIDE_PLAYER)
	system.mark_unit_acted(0)
	assert_int(system.get_active_side()).is_equal(SIDE_OTHER)
	system.mark_unit_acted(3)
	assert_int(system.get_active_side()).is_equal(SIDE_PLAYER)
	system.mark_unit_acted(1)
	assert_bool(system.can_unit_act(1)).is_false()
	system.mark_unit_acted(2)
	var available_after_round: Array = system.get_available_indexes(SIDE_PLAYER)
	assert_that(available_after_round).contains(0)
	assert_that(available_after_round).contains(1)
	assert_that(available_after_round).contains(2)
	assert_int(system.get_active_side()).is_equal(SIDE_PLAYER)
