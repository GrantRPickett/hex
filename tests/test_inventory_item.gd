extends GdUnitTestSuite

const InventoryItem := preload("res://Gameplay/inventory_item.gd")

func test_duplicate_instance_preserves_values_without_regenerating_uuid() -> void:
	var item: InventoryItem = InventoryItem.new()
	item.item_name = "Test"
	item.attribute_modifiers = {"flow": 1}
	item.equipped = true
	item.origin_id = "template"
	var original_uuid := item.uuid

	var clone: InventoryItem = item.duplicate_instance()
	assert_object(clone).is_not_equal(item)
	assert_str(clone.uuid).is_equal(original_uuid)
	assert_dict(clone.attribute_modifiers).is_equal(item.attribute_modifiers)
	clone.attribute_modifiers["flow"] = 3
	assert_int(item.attribute_modifiers["flow"]).is_equal(1)

func test_duplicate_instance_regenerates_uuid_when_requested() -> void:
	var item: InventoryItem = InventoryItem.new()
	var clone: InventoryItem = item.duplicate_instance(true)
	assert_str(clone.uuid).is_not_equal(item.uuid)
