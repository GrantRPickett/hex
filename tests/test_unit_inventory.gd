extends GdUnitTestSuite

func test_remove_item_from_inventory() -> void:
	var inv: UnitInventory = UnitInventory.new()
	var item: InventoryItem = InventoryItem.new()
	inv.add_item_to_inventory(item)
	
	assert_that(inv.remove_item_from_inventory(item)).is_true()
	assert_that(inv.get_items().has(item)).is_false()
	inv.free()

func test_has_item_by_id() -> void:
	var inv: UnitInventory = UnitInventory.new()
	var item: InventoryItem = InventoryItem.new()
	item.origin_id = "test_item_id"
	inv.add_item_to_inventory(item)
	
	assert_that(inv.has_item_by_id("test_item_id")).is_true()
	assert_that(inv.has_item_by_id("other_id")).is_false()
	inv.free()
