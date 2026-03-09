extends GdUnitTestSuite

const TaskConditionHandlerClass = preload("res://Gameplay/narrative/task/task_condition_handler.gd")
const ObjectiveClass = preload("res://Gameplay/narrative/task/objective.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")
const UnitClass = preload("res://Gameplay/targets/unit.gd")

func test_check_objective_failed_returns_false_if_no_unit_manager() -> void:
	var handler = auto_free(TaskConditionHandlerClass.new())
	var obj = auto_free(ObjectiveClass.new())
	assert_bool(handler.check_objective_failed(obj)).is_false()

func test_check_objective_failed_returns_false_if_zero_units() -> void:
	var handler = auto_free(TaskConditionHandlerClass.new())
	var um = auto_free(Stubs.FakeUnitManager.new())
	handler.setup(null, um)
	var obj = auto_free(ObjectiveClass.new())
	assert_bool(handler.check_objective_failed(obj)).is_false()

func test_check_objective_failed_returns_true_if_no_player_units() -> void:
	var handler = auto_free(TaskConditionHandlerClass.new())
	var um = auto_free(Stubs.FakeUnitManager.new())
	var enemy = auto_free(Stubs.FakeUnit.new())
	enemy.faction = UnitClass.Faction.ENEMY
	um._units.append(enemy)
	handler.setup(null, um)
	var obj = auto_free(ObjectiveClass.new())
	assert_bool(handler.check_objective_failed(obj)).is_true()

func test_check_objective_failed_returns_true_if_all_player_units_dead() -> void:
	var handler = auto_free(TaskConditionHandlerClass.new())
	var um = auto_free(Stubs.FakeUnitManager.new())
	var player = auto_free(Stubs.FakeUnit.new())
	player.faction = UnitClass.Faction.PLAYER
	var ap = auto_free(Stubs.FakeActionPointsComponent.new())
	ap._willpower = 0
	player.action_points_template = ap
	player.res = ap
	um._units.append(player)
	handler.setup(null, um)
	var obj = auto_free(ObjectiveClass.new())
	assert_bool(handler.check_objective_failed(obj)).is_true()

func test_check_objective_failed_returns_false_if_player_unit_alive() -> void:
	var handler = auto_free(TaskConditionHandlerClass.new())
	var um = auto_free(Stubs.FakeUnitManager.new())
	var player = auto_free(Stubs.FakeUnit.new())
	player.faction = UnitClass.Faction.PLAYER
	var ap = auto_free(Stubs.FakeActionPointsComponent.new())
	ap._willpower = 10
	player.action_points_template = ap
	player.res = ap
	um._units.append(player)
	handler.setup(null, um)
	var obj = auto_free(ObjectiveClass.new())
	assert_bool(handler.check_objective_failed(obj)).is_false()
