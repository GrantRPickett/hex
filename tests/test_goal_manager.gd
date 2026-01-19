extends GdUnitTestSuite

var _goal_manager: GoalManager

func before() -> void:
	# Create fresh manager for each test, don't auto_free to avoid cross-test interference
	_goal_manager = GoalManager.new()

func after() -> void:
	# Manually free the manager after each test
	if _goal_manager:
		_goal_manager.free()
		_goal_manager = null

func test_get_goal_count() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	var goals: Array[Goal] = []

	_goal_manager.setup(coords, goals, null)

	assert_int(_goal_manager.get_goal_count()).is_equal(3)

func test_get_goal_count_empty() -> void:
	_goal_manager.setup([], [], null)

	assert_int(_goal_manager.get_goal_count()).is_equal(0)

func test_get_progress_initial() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	assert_int(_goal_manager.get_progress(0, Unit.Faction.PLAYER)).is_equal(0)

func test_get_progress_invalid_index() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	assert_int(_goal_manager.get_progress(5, Unit.Faction.PLAYER)).is_equal(0)
	assert_int(_goal_manager.get_progress(-1, Unit.Faction.PLAYER)).is_equal(0)

func test_get_required_amount() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	# Default amount is 100
	assert_int(_goal_manager.get_required_amount(0)).is_equal(100)

func test_get_required_amount_invalid() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	assert_int(_goal_manager.get_required_amount(5)).is_equal(0)
	assert_int(_goal_manager.get_required_amount(-1)).is_equal(0)

func test_get_required_type() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	# Default type is "grit"
	assert_that(_goal_manager.get_required_type(0)).is_equal("grit")

func test_get_required_type_invalid() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	assert_that(_goal_manager.get_required_type(5)).is_equal("")
	assert_that(_goal_manager.get_required_type(-1)).is_equal("")

func test_apply_progress() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	_goal_manager.apply_progress(0, unit)

	# Default unit has 1 attribute, so progress should increase by at least 1
	assert_int(_goal_manager.get_progress(0, Unit.Faction.PLAYER)).is_greater(0)

func test_apply_progress_multiple_calls() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	_goal_manager.apply_progress(0, unit)
	var progress1 = _goal_manager.get_progress(0, Unit.Faction.PLAYER)

	_goal_manager.apply_progress(0, unit)
	var progress2 = _goal_manager.get_progress(0, Unit.Faction.PLAYER)

	assert_int(progress2).is_greater(progress1)

func test_apply_progress_different_factions() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	var player_unit = auto_free(Unit.new())
	player_unit.faction = Unit.Faction.PLAYER
	var enemy_unit = auto_free(Unit.new())
	enemy_unit.faction = Unit.Faction.ENEMY

	_goal_manager.apply_progress(0, player_unit)
	_goal_manager.apply_progress(0, enemy_unit)

	var player_progress = _goal_manager.get_progress(0, Unit.Faction.PLAYER)
	var enemy_progress = _goal_manager.get_progress(0, Unit.Faction.ENEMY)

	# Both should have tracked progress independently
	assert_int(player_progress).is_greater(0)
	assert_int(enemy_progress).is_greater(0)

func test_process_turn_progress() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)

	var unit_manager = auto_free(UnitManager.new())
	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	unit_manager.add_unit(unit, Vector2i(0, 0), true)

	_goal_manager.process_turn_progress(unit_manager)

	# Progress should have been applied to the unit at the goal location
	assert_int(_goal_manager.get_progress(0, Unit.Faction.PLAYER)).is_greater(0)
