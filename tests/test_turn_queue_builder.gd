extends GdUnitTestSuite

var builder: TurnQueueBuilder
var unit_manager: UnitManager

func before_test() -> void:
	unit_manager = auto_free(UnitManager.new())
	builder = TurnQueueBuilder.new(unit_manager)

func test_get_side_rotation() -> void:
	var rot1 = builder.get_side_rotation(GameConstants.Side.PLAYER)
	assert_that(rot1).contains_exactly([GameConstants.Side.PLAYER, GameConstants.Side.ENEMY, GameConstants.Side.NEUTRAL])

	var rot2 = builder.get_side_rotation(GameConstants.Side.ENEMY)
	assert_that(rot2).contains_exactly([GameConstants.Side.ENEMY, GameConstants.Side.NEUTRAL, GameConstants.Side.PLAYER])

func test_build_from_active_units() -> void:
	var units_by_side = {
		GameConstants.Side.PLAYER: [0, 1],
		GameConstants.Side.ENEMY: [2],
		GameConstants.Side.NEUTRAL: []
	}
	var queue = builder.build_from_active_units(units_by_side, GameConstants.Side.PLAYER)
	assert_that(queue).contains_exactly([0, 2, 1])

func test_determine_start_side() -> void:
	var units_by_side = {
		GameConstants.Side.PLAYER: [0],
		GameConstants.Side.ENEMY: [1]
	}
	var start = builder.determine_start_side(units_by_side, 1, {}, GameConstants.Side.PLAYER)
	assert_that(start).is_equal(GameConstants.Side.PLAYER)

func test_find_next_active_side() -> void:
	var units_by_side = {
		GameConstants.Side.PLAYER: [0],
		GameConstants.Side.ENEMY: [],
		GameConstants.Side.NEUTRAL: [1]
	}
	var next_side = builder.find_next_active_side(GameConstants.Side.PLAYER, units_by_side)
	assert_that(next_side).is_equal(GameConstants.Side.NEUTRAL)

func test_classify_unit_side() -> void:
	var unit: Unit = Unit.new()
	unit.faction = GameConstants.Faction.PLAYER
	var side = builder.classify_unit_side(unit, 0)
	assert_that(side).is_equal(GameConstants.Side.PLAYER)

	unit.faction = GameConstants.Faction.NEUTRAL
	side = builder.classify_unit_side(unit, 1)
	assert_that(side).is_equal(GameConstants.Side.NEUTRAL)
	unit.free()

func test_get_active_units_by_side_empty() -> void:
	var units = builder.get_active_units_by_side()
	assert_that(units[GameConstants.Side.PLAYER]).is_empty()
