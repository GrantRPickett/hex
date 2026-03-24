extends GdUnitTestSuite

const AttackEvaluatorClass := preload("res://Gameplay/turn/ai/attack_evaluator.gd")
const AIContextClass := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIActionClass := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")

class NonnearFakeUnit extends Stubs.FakeUnit:
	func get_near_units(_units: Array, _r: float = 1.5) -> Array:
		return []

func test_evaluate_returns_empty_for_neutral_units() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = UnitClass.FACTION.NEUTRAL

	var context: AIContextClass = AIContextClass.new()
	var actions = evaluator.evaluate(unit, context)
	assert_array(actions).is_empty()

func test_evaluate_returns_attack_for_near_enemy() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	enemy.faction = UnitClass.FACTION.ENEMY
	enemy.willpower = 10

	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.faction = UnitClass.FACTION.PLAYER
	unit._hostiles = [enemy]

	# Stubs.FakeUnit's get_near_units returns hostiles in the targets list
	var context: AIContextClass = AIContextClass.new()
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()
	context.unit_manager.add_unit(unit, Vector2i(1, 1))


	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	assert_int(actions[0].type).is_equal(GameConstants.AI.ACTION_ATTACK)
	assert_object(actions[0].target).is_same(enemy)
	# (Base score of attack priority 10 * multiplier 10.0) * weight_opposed 0.85 = 85.0
	assert_float(actions[0].score).is_equal(85.0)

func test_evaluate_returns_move_to_enemy_for_distant_enemy() -> void:
	var evaluator: AttackEvaluatorClass = auto_free(AttackEvaluatorClass.new())
	var enemy: Stubs.FakeUnit = Stubs.FakeUnit.new()
	enemy.set_grid_location(Vector2i(3, 3))
	enemy.faction = UnitClass.FACTION.ENEMY
	enemy.willpower = 10

	var unit: NonnearFakeUnit = NonnearFakeUnit.new()
	unit.faction = UnitClass.FACTION.PLAYER
	unit.set_grid_location(Vector2i(1, 1))
	unit._hostiles = [enemy]
	# Move to (2,2) to be near to (3,3)
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var terrain := Stubs.FakeTerrainMap.new()
	# Neighbors of (3,3) should include (2,2)
	terrain.neighbor_map[Vector2i(3, 3)] = [Vector2i(2, 2)]

	var context: AIContextClass = AIContextClass.new()
	context.terrain_map = terrain as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()
	context.unit_manager.add_unit(unit, Vector2i(1, 1))


	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_greater_equal(1)
	var move_action: AIActionClass = null
	for act in actions:
		if act.type == GameConstants.AI.ACTION_MOVE_TO_ENEMY:
			move_action = act
			break
	assert_object(move_action).is_not_null()
	assert_object(move_action.target).is_same(enemy)
	assert_array(move_action.path).is_not_empty()
