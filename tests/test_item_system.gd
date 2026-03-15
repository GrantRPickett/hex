# GdUnitGeneratedTest
extends GdUnitTestSuite

func before_test() -> void:
	# Ensure templates are loaded or accessible
	pass

func test_item_registry_instancing() -> void:
	# Create a mock template if needed, but we can use the ones we just created
	var item_id: String = "bronze_flow"
	var instance1: InventoryItem = ItemRegistry.create_instance(item_id)
	var instance2: InventoryItem = ItemRegistry.create_instance(item_id)
	
	assert_object(instance1).is_not_null()
	assert_object(instance2).is_not_null()
	assert_object(instance1).is_not_same(instance2)
	assert_str(instance1.uuid).is_not_equal(instance2.uuid)
	assert_str(instance1.get_item_name()).is_equal("Bronze Flow")
	
	# Verify modification separation
	instance1.equipped = false
	assert_bool(instance1.equipped).is_false()
	assert_bool(instance2.equipped).is_true()

func test_item_serialization() -> void:
	var item_id: String = "bronze_flow"
	var instance: InventoryItem = ItemRegistry.create_instance(item_id)
	instance.equipped = true
	
	var data = instance.to_dict()
	assert_str(data.get("template_id", "")).is_equal(item_id)
	assert_bool(data.get("equipped", false)).is_true()
	
	var restored = InventoryItem.from_dict(data)
	# Manually set template back as per UnitSerializer logic
	restored.template = ItemRegistry.get_template(data["template_id"])
	
	assert_str(restored.get_item_name()).is_equal("Bronze Flow")
	assert_bool(restored.equipped).is_true()
	assert_str(restored.uuid).is_equal(instance.uuid)
