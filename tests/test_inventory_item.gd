extends GdUnitTestSuite

const InventoryItem := preload("res://Gameplay/targets/inventory_item.gd")
const ItemTemplate := preload("res://Resources/items/item_template.gd")

func test_duplicate_instance_preserves_values_without_regenerating_uuid() -> void:
	var item: InventoryItem = InventoryItem.new()
	item.equipped = true
	item.origin_id = "template"
	var original_uuid := item.uuid

	var clone: InventoryItem = item.duplicate_instance()
	assert_object(clone).is_not_null()
	assert_object(clone).is_not_same(item)
	assert_str(clone.uuid).is_equal(original_uuid)
	assert_bool(clone.equipped).is_true()
	assert_str(clone.origin_id).is_equal("template")

func test_duplicate_instance_regenerates_uuid_when_requested() -> void:
	var item: InventoryItem = InventoryItem.new()
	var clone: InventoryItem = item.duplicate_instance(true)
	assert_str(clone.uuid).is_not_equal(item.uuid)

# ---------------------------------------------------------------------------
# to_dict / from_dict
# ---------------------------------------------------------------------------

func test_to_dict_contains_all_fields() -> void:
	var item: InventoryItem = InventoryItem.new()
	var template: ItemTemplate = ItemTemplate.new()
	template.item_id = "test_item"
	item.template = template
	item.equipped = true
	item.origin_id = "loot_drop"
	
	var d := item.to_dict()
	assert_str(d.get("template_id", "")).is_equal("test_item")
	assert_bool(d.get("equipped", false)).is_true()
	assert_str(d.get("origin_id", "")).is_equal("loot_drop")
	assert_str(d.get("uuid", "")).is_equal(item.uuid)

func test_from_dict_restores_all_fields() -> void:
	var item: InventoryItem = InventoryItem.new()
	item.equipped = false
	item.origin_id = "shop"
	var d := item.to_dict()

	var restored: InventoryItem = InventoryItem.from_dict(d)
	auto_free(restored)
	assert_bool(restored.equipped).is_false()
	assert_str(restored.origin_id).is_equal("shop")
	assert_str(restored.uuid).is_equal(item.uuid)

func test_to_dict_from_dict_uuid_preserved() -> void:
	var item: InventoryItem = InventoryItem.new()
	var fixed_uuid := "1234-5678-abcd-ef01"
	item.uuid = fixed_uuid
	var restored: InventoryItem = InventoryItem.from_dict(item.to_dict())
	auto_free(restored)
	assert_str(restored.uuid).is_equal(fixed_uuid)

func test_quest_item_recognition() -> void:
	var item: InventoryItem = InventoryItem.new()
	var template: ItemTemplate = ItemTemplate.new()
	template.quest_item = true
	item.template = template
	
	assert_bool(item.is_quest_item()).is_true()
	
	template.quest_item = false
	assert_bool(item.is_quest_item()).is_false()
