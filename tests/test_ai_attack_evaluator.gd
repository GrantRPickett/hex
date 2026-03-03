extends GdUnitTestSuite

const AttackEvaluatorClass := preload("res://Gameplay/turn/ai/attack_evaluator.gd")
const AIContextClass := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIActionClass := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")

func test_evaluate_returns_empty_for_neutral_units() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = UnitClass.Faction.NEUTRAL

	var context: AIContextClass = AIContextClass.new()
	var actions: Array[AIActionClass] = evaluator.evaluate(unit, context)
	assert_that(actions).is_empty()

func test_evaluate_returns_attack_for_adjacent_enemy() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	enemy.faction = UnitClass.Faction.ENEMY

	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = UnitClass.Faction.PLAYER
	unit._hostiles = [enemy]

	# Stubs.FakeUnit's get_adjacent_units returns hostiles in the targets list
	var context: AIContextClass = AIContextClass.new()
	var actions: Array[AIActionClass] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(AttackEvaluatorClass.ACTION_ATTACK)
	assert_that(actions[0].target).is_same(enemy)
	assert_that(actions[0].score).is_equal(AttackEvaluatorClass.SCORE_ATTACK_BASE)

func test_evaluate_returns_move_to_enemy_for_distant_enemy() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	enemy.set_grid_location(Vector2i(3, 3))
	enemy.faction = UnitClass.Faction.ENEMY

	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = UnitClass.Faction.PLAYER
	unit.set_grid_location(Vector2i(1, 1))
	unit._hostiles = [enemy]
	# Move to (2,2) to be adjacent to (3,3)
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var terrain := Stubs.FakeTerrainMap.new()
	# Neighbors of (3,3) should include (2,2)
	terrain.neighbor_map[Vector2i(3, 3)] = [Vector2i(2, 2)]

	var context: AIContextClass = AIContextClass.new()
	context.terrain_map = terrain as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	var actions: Array[AIActionClass] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_greater_equal(1)
	var move_action: AIActionClass = null
	for act in actions:
		if act.type == AttackEvaluatorClass.ACTION_MOVE_TO_ENEMY:
			move_action = act
			break
	assert_that(move_action).is_not_null()
	assert_that(move_action.target).is_same(enemy)
	assert_that(move_action.path).is_not_empty()
