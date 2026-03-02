extends GdUnitTestSuite

const LootEvaluator := preload("res://Gameplay/turn/ai/loot_evaluator.gd")
const AIContext := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIAction := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")

func test_evaluate_returns_loot_action_if_loot_at_start_coord() -> void:
	var evaluator: LootEvaluator = auto_free(LootEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit._grid_location = Vector2i(1, 1)

	var context: AIContext = AIContext.new()
	context.loot_manager = Stubs.FakeLootManager.new()
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	context.loot_manager.add_loot(Node.new(), Vector2i(1, 1))

	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(LootEvaluator.ACTION_LOOT)
	assert_that(actions[0].score).is_equal(LootEvaluator.SCORE_LOOT_BASE)

func test_evaluate_returns_move_to_loot_action_for_reachable_loot() -> void:
	var evaluator: LootEvaluator = auto_free(LootEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit._grid_location = Vector2i(1, 1)
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var context: AIContext = AIContext.new()
	context.loot_manager = Stubs.FakeLootManager.new()
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	# Add loot at a reachable location but NOT the starting location
	var loot_node = Node.new()
	context.loot_manager.add_loot(loot_node, Vector2i(2, 2))

	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(LootEvaluator.ACTION_MOVE_TO_LOOT)
	assert_that(actions[0].target).is_same(loot_node)
	assert_that(actions[0].path).is_not_empty()

func test_evaluate_returns_empty_when_missing_context() -> void:
	var evaluator: LootEvaluator = auto_free(LootEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()

	var partial_context: AIContext = AIContext.new()

	var actions: Array[AIAction] = evaluator.evaluate(unit, partial_context)
	assert_that(actions).is_empty()
