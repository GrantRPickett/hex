extends GdUnitTestSuite

const LootManager := preload("res://Gameplay/loot_manager.gd")
const Loot := preload("res://Gameplay/loot.gd")
const InventoryItem := preload("res://Gameplay/inventory_item.gd")

func test_take_all_items_clears_inventory() -> void:
	var loot := auto_free(Loot.new())
	var item := InventoryItem.new()
	item.item_name = "Gem"
	loot.add_items([item])

	var taken: Array[InventoryItem] = loot.take_all_items()

	assert_int(taken.size()).is_equal(1)
	assert_str(taken[0].item_name).is_equal("Gem")
	assert_int(loot.inventory.size()).is_equal(0)

func test_collect_all_loot_items_removes_entries() -> void:
	var loot_manager := auto_free(LootManager.new())
	var loot := Loot.new()
	var item := InventoryItem.new()
	item.item_name = "Coin"
	loot.add_items([item])
	loot_manager.add_loot(loot, Vector2i.ZERO)

	var collected: Array[InventoryItem] = loot_manager.collect_all_loot_items()

	assert_int(collected.size()).is_equal(1)
	assert_str(collected[0].item_name).is_equal("Coin")
	assert_int(loot_manager.get_loot_count()).is_equal(0)