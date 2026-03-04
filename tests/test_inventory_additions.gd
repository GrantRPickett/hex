extends GdUnitTestSuite

# Tests for UnitInventory and InventoryComponent's add_item_to_inventory

func test_unit_inventory_add_item_to_inventory_success() -> void:
	var inv: UnitInventory = auto_free(UnitInventory.new())
	var item: InventoryItem = auto_free(InventoryItem.new())

	var success := inv.add_item_to_inventory(item)
	assert_bool(success).is_true()
	assert_bool(item.equipped).is_false()
	assert_array(inv.get_items()).contains(item)

func test_unit_inventory_add_item_to_inventory_null_fails() -> void:
	var inv: UnitInventory = auto_free(UnitInventory.new())
	var success := inv.add_item_to_inventory(null)
	assert_bool(success).is_false()
	assert_array(inv.get_items()).is_empty()

func test_unit_inventory_add_item_to_inventory_duplicate_fails() -> void:
	var inv: UnitInventory = auto_free(UnitInventory.new())
	var item: InventoryItem = auto_free(InventoryItem.new())

	inv.add_item_to_inventory(item)
	var success := inv.add_item_to_inventory(item) # Add again
	assert_bool(success).is_false()
	assert_int(inv.get_items().size()).is_equal(1)

func test_inventory_component_add_item_to_inventory_success() -> void:
	var comp: InventoryComponent = auto_free(InventoryComponent.new())
	var test_owner: Node = auto_free(Node.new())
	comp.setup(test_owner)

	var item: InventoryItem = auto_free(InventoryItem.new())
	var success := comp.add_item_to_inventory(item)
	assert_bool(success).is_true()

func test_inventory_component_add_item_to_inventory_null_inventory_fails() -> void:
	var comp: InventoryComponent = auto_free(InventoryComponent.new())
	# Not setup, so internal inventory is null
	var item: InventoryItem = auto_free(InventoryItem.new())
	var success := comp.add_item_to_inventory(item)
	assert_bool(success).is_false()
