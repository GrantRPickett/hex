extends GdUnitTestSuite

# This test verifies that ItemRegistry can load templates even if get_template is called before _ready()
# which simulates the race condition with SaveManager.

func test_lazy_loading_templates() -> void:
	# 1. Simulate uninitialized registry
	ItemRegistry._templates = {}
	
	# 2. Call get_template (this should trigger _load_templates via lazy loading)
	var template = ItemRegistry.get_template("bronze_focus")
	
	# 3. Verify it worked
	assert_object(template).is_not_null()
	assert_str(template.item_id).is_equal("bronze_focus")
	assert_bool(ItemRegistry._templates.is_empty()).is_false()
