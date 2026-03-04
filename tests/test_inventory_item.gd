extends GdUnitTestSuite

const InventoryItem := preload("res://Gameplay/targets/inventory_item.gd")

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

# ---------------------------------------------------------------------------
# to_dict
# ---------------------------------------------------------------------------

func test_to_dict_contains_all_fields() -> void:
	var item: InventoryItem = InventoryItem.new()
	item.item_name = "Sword"
	item.attribute_modifiers = {"grit": 3}
	item.equipped = true
	item.origin_id = "loot_drop"
	item.quest = true
	var d := item.to_dict()
	assert_str(d.get("item_name", "")).is_equal("Sword")
	assert_dict(d.get("attribute_modifiers", {})).is_equal({"grit": 3})
	assert_bool(d.get("equipped", false)).is_true()
	assert_str(d.get("origin_id", "")).is_equal("loot_drop")
	assert_bool(d.get("quest", false)).is_true()
	assert_str(d.get("uuid", "")).is_equal(item.uuid)

func test_to_dict_defaults() -> void:
	var item: InventoryItem = InventoryItem.new()
	var d := item.to_dict()
	assert_str(d.get("item_name", "MISSING")).is_equal("")
	assert_bool(d.get("equipped", true)).is_false()
	assert_bool(d.get("quest", true)).is_false()

# ---------------------------------------------------------------------------
# from_dict round-trip
# ---------------------------------------------------------------------------

func test_from_dict_restores_all_fields() -> void:
	var item: InventoryItem = InventoryItem.new()
	item.item_name = "Shield"
	item.attribute_modifiers = {"shade": 2}
	item.equipped = false
	item.origin_id = "shop"
	item.quest = false
	var d := item.to_dict()

	var restored: InventoryItem = InventoryItem.from_dict(d)
	auto_free(restored)
	assert_str(restored.item_name).is_equal("Shield")
	assert_dict(restored.attribute_modifiers).is_equal({"shade": 2})
	assert_bool(restored.equipped).is_false()
	assert_str(restored.origin_id).is_equal("shop")
	assert_str(restored.uuid).is_equal(item.uuid)

func test_from_dict_with_empty_dict_uses_defaults() -> void:
	var restored: InventoryItem = InventoryItem.from_dict({})
	auto_free(restored)
	assert_str(restored.item_name).is_equal("")
	assert_bool(restored.equipped).is_false()
	assert_bool(restored.quest).is_false()

func test_to_dict_from_dict_uuid_preserved() -> void:
	var item: InventoryItem = InventoryItem.new()
	var fixed_uuid := "1234-5678-abcd-ef01"
	item.uuid = fixed_uuid
	var restored: InventoryItem = InventoryItem.from_dict(item.to_dict())
	auto_free(restored)
	assert_str(restored.uuid).is_equal(fixed_uuid)
