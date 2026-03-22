extends GdUnitTestSuite

const LootEvaluatorClass := preload("res://Gameplay/turn/ai/loot_evaluator.gd")
const AIContextClass := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIActionClass := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")
const LootClass := preload("res://Gameplay/targets/loot.gd")


func test_evaluate_returns_loot_action_if_loot_at_start_coord() -> void:
	var evaluator: LootEvaluatorClass = auto_free(LootEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.set_grid_location(Vector2i(1, 1))

	var context: AIContextClass = AIContextClass.new()
	context.loot_manager = Stubs.FakeLootManager.new()
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()
	context.unit_manager.add_unit(unit, Vector2i(1, 1))


	context.loot_manager.add_loot(auto_free(LootClass.new()), Vector2i(1, 1))

	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].type).is_equal(GameConstants.AI.ACTION_LOOT)
	# (Base score of objective priority 5 * multiplier 14.0) = 70.0
	assert_float(actions[0].score).is_equal(70.0)

func test_evaluate_returns_move_to_loot_action_for_reachable_loot() -> void:
	var evaluator: LootEvaluatorClass = auto_free(LootEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.set_grid_location(Vector2i(1, 1))
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var context: AIContextClass = AIContextClass.new()
	context.loot_manager = Stubs.FakeLootManager.new()
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()
	context.unit_manager.add_unit(unit, Vector2i(1, 1))


	# Add loot at a reachable location but NOT the starting location
	var loot_node = auto_free(LootClass.new())
	context.loot_manager.add_loot(loot_node, Vector2i(2, 2))

	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].type).is_equal(GameConstants.AI.ACTION_MOVE_TO_LOOT)
	assert_object(actions[0].target).is_same(loot_node)
	assert_array(actions[0].path).is_not_empty()

func test_evaluate_returns_empty_when_missing_context() -> void:
	var evaluator: LootEvaluatorClass = auto_free(LootEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()

	var partial_context: AIContextClass = AIContextClass.new()

	var actions = evaluator.evaluate(unit, partial_context)
	assert_array(actions).is_empty()
