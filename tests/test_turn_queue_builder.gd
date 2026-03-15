extends GdUnitTestSuite

var builder: TurnQueueBuilder
var unit_manager: UnitManager

func before_test() -> void:
	unit_manager = auto_free(UnitManager.new())
	builder = TurnQueueBuilder.new(unit_manager)

func test_get_side_rotation() -> void:
	var rot1 = builder.get_side_rotation(TurnSystem.Side.PLAYER)
	assert_that(rot1).contains_exactly([TurnSystem.Side.PLAYER, TurnSystem.Side.ENEMY, TurnSystem.Side.NEUTRAL])
	
	var rot2 = builder.get_side_rotation(TurnSystem.Side.ENEMY)
	assert_that(rot2).contains_exactly([TurnSystem.Side.ENEMY, TurnSystem.Side.NEUTRAL, TurnSystem.Side.PLAYER])

func test_build_from_active_units() -> void:
	var units_by_side = {
		TurnSystem.Side.PLAYER: [0, 1],
		TurnSystem.Side.ENEMY: [2],
		TurnSystem.Side.NEUTRAL: []
	}
	var queue = builder.build_from_active_units(units_by_side, TurnSystem.Side.PLAYER)
	assert_that(queue).contains_exactly([0, 2, 1])

func test_determine_start_side() -> void:
	var units_by_side = {
		TurnSystem.Side.PLAYER: [0],
		TurnSystem.Side.ENEMY: [1]
	}
	var start = builder.determine_start_side(units_by_side, 1, {}, TurnSystem.Side.PLAYER)
	assert_that(start).is_equal(TurnSystem.Side.PLAYER)

func test_find_next_active_side() -> void:
	var units_by_side = {
		TurnSystem.Side.PLAYER: [0],
		TurnSystem.Side.ENEMY: [],
		TurnSystem.Side.NEUTRAL: [1]
	}
	var next_side = builder.find_next_active_side(TurnSystem.Side.PLAYER, units_by_side)
	assert_that(next_side).is_equal(TurnSystem.Side.NEUTRAL)

func test_classify_unit_side() -> void:
	var unit: Unit = Unit.new()
	unit.faction = Unit.Faction.PLAYER
	# Without adding to unit manager properly, classify might just return ENEMY since is_player_controlled defaults to false if empty.
	# But let's check it doesn't crash.
	var side = builder.classify_unit_side(unit, 0)
	assert_that(side).is_equal(TurnSystem.Side.ENEMY) # Default behavior of UnitManager stub
	
	unit.faction = Unit.Faction.NEUTRAL
	side = builder.classify_unit_side(unit, 1)
	assert_that(side).is_equal(TurnSystem.Side.NEUTRAL)
	unit.free()

func test_get_active_units_by_side_empty() -> void:
	var units = builder.get_active_units_by_side()
	assert_that(units[TurnSystem.Side.PLAYER]).is_empty()
