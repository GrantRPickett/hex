extends GdUnitTestSuite

const AttackEvaluator := preload("res://Gameplay/turn/ai/attack_evaluator.gd")
const AIContext := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIAction := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")

func test_evaluate_returns_empty_for_neutral_units() -> void:
	var evaluator: AttackEvaluator = auto_free(AttackEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = Unit.Faction.NEUTRAL

	var context: AIContext = AIContext.new()
	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions).is_empty()

func test_evaluate_returns_attack_for_adjacent_enemy() -> void:
	var evaluator: AttackEvaluator = auto_free(AttackEvaluator.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit._hostiles = [enemy]

	# Just use a mock response on FakeUnit for get_adjacent_units
	var u2: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	u2._hostiles = [enemy]

	# Create a specialized mock unit to return the adjacent enemy
	var script_src = """
	extends "res://tests/fixtures/test_stubs.gd".FakeUnit
	var _mock_adj = []
	func get_adjacent_units(units: Array, dist: float = 1.5) -> Array:
		return _mock_adj
	"""
	var mock_script = GDScript.new()
	mock_script.source_code = script_src
	mock_script.reload()
	var mock_unit = auto_free(mock_script.new())
	mock_unit.faction = Unit.Faction.ENEMY
	mock_unit._hostiles = [enemy]
	mock_unit._mock_adj = [enemy]

	var context: AIContext = AIContext.new()
	var actions: Array[AIAction] = evaluator.evaluate(mock_unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(AttackEvaluator.ACTION_ATTACK)
	assert_that(actions[0].target).is_same(enemy)
	assert_that(actions[0].score).is_equal(AttackEvaluator.SCORE_ATTACK_BASE)

func test_evaluate_returns_move_to_enemy_for_distant_enemy() -> void:
	var evaluator: AttackEvaluator = auto_free(AttackEvaluator.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	enemy._grid_location = Vector2i(2, 2)

	var script_src = """
	extends "res://tests/fixtures/test_stubs.gd".FakeUnit
	var _mock_hostiles = []
	func get_hostile_units() -> Array: return _mock_hostiles
	func get_adjacent_units(units: Array, dist: float = 1.5) -> Array: return []
	func get_units_in_range(units: Array, dist: float) -> Array: return _mock_hostiles
	"""
	var mock_script = GDScript.new()
	mock_script.source_code = script_src
	mock_script.reload()
	var unit = auto_free(mock_script.new())
	unit.faction = Unit.Faction.ENEMY
	unit._mock_hostiles = [enemy]

	var context: AIContext = AIContext.new()
	context.terrain_map = Stubs.FakeTerrainMap.new({Vector2i(2, 2): [Vector2i(1, 2)]}) as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	unit._paths[Vector2i(1, 2)] = [Vector2i(0, 0), Vector2i(1, 2)]

	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_greater_equal(1)
	assert_that(actions[0].type).is_equal(AttackEvaluator.ACTION_MOVE_TO_ENEMY)
	assert_that(actions[0].target).is_same(enemy)
