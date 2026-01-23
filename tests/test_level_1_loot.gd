extends GdUnitTestSuite

const Level1 := preload("res://Resources/levels/level_1.tres")
const GameplayScene := preload("res://Gameplay/gameplay.tscn")

func test_loot_spawned_in_level_1(runner: GdUnitSceneRunner) -> void:
	# Load Gameplay scene with Level 1
	var scene = runner.invoke("set_level_resource", Level1).simulate_frames(20)

	# Verify LootManager exists
	var loot_manager = scene._loot_manager
	assert_object(loot_manager).is_not_null()

	# Verify loot count
	assert_int(loot_manager.get_loot_count()).is_equal(1)

	# Verify loot coordinate
	var loot_coord = loot_manager.get_coord(0)
	assert_vector(loot_coord).is_equal(Vector2i(2, 2))

	# Verify loot item data
	var loot_node = loot_manager.get_loot(0)
	assert_object(loot_node).is_not_null()
	var sprite: Sprite2D = loot_node.get_node_or_null("Sprite2D")
	assert_object(sprite).is_not_null()
	if sprite and sprite.texture:
		assert_str(sprite.texture.resource_path).is_equal("res://icon.svg")
	if loot_node.has_method("get_item"):
		var item = loot_node.get_item()
		assert_str(item.item_name).is_equal("Old Coin")
