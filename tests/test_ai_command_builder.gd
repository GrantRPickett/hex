extends GdUnitTestSuite

const AICommandBuilderClass := preload("res://Gameplay/turn/ai/ai_command_builder.gd")
const AIActionClass := preload("res://Gameplay/turn/ai/ai_action.gd")
const AIContextClass := preload("res://Gameplay/turn/ai/ai_context.gd")
const LootClass := preload("res://Gameplay/targets/loot.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

func test_build_loot_command_from_vector2i_target() -> void:
	var builder: AICommandBuilderClass = auto_free(AICommandBuilderClass.new())
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	var context: AIContextClass = auto_free(AIContextClass.new())
	context.unit_manager = auto_free(Stubs.FakeUnitManager.new())
	context.unit_manager.add_unit(unit, Vector2i(0, 0))
	
	var target_coord := Vector2i(1, 2)
	var action: AIActionClass = auto_free(AIActionClass.new(GameConstants.AI.ACTION_LOOT, target_coord, [], 10.0))
	
	var result := builder.build(action, unit, context)
	
	assert_dict(result).is_not_empty()
	assert_bool(result["cmd"] is LootCommand).is_true()
	var payload = result["payload"]
	assert_int(payload["loot_coord"].x).is_equal(1)
	assert_int(payload["loot_coord"].y).is_equal(2)

func test_build_loot_command_from_loot_object_target() -> void:
	var builder: AICommandBuilderClass = auto_free(AICommandBuilderClass.new())
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	var context: AIContextClass = auto_free(AIContextClass.new())
	context.unit_manager = auto_free(Stubs.FakeUnitManager.new())
	context.unit_manager.add_unit(unit, Vector2i(0, 0))
	
	var loot_node: LootClass = auto_free(LootClass.new())
	loot_node.set_external_grid_coord(Vector2i(3, 4))
	
	var action: AIActionClass = auto_free(AIActionClass.new(GameConstants.AI.ACTION_LOOT, loot_node, [], 10.0))
	
	var result := builder.build(action, unit, context)
	
	assert_dict(result).is_not_empty()
	assert_bool(result["cmd"] is LootCommand).is_true()
	var payload = result["payload"]
	assert_int(payload["loot_coord"].x).is_equal(3)
	assert_int(payload["loot_coord"].y).is_equal(4)
