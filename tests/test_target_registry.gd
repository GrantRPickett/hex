extends GdUnitTestSuite

func before_test() -> void:
	TargetDiscoveryService.clear_registry()

func test_target_registration() -> void:
	var target = auto_free(Node2D.new())
	target.set_script(load("res://Gameplay/targets/target.gd"))

	# Manually trigger ready since it's not in the tree
	target._ready()

	var generated_id = target.get_target_id()
	assert_str(generated_id).is_not_empty()
	assert_str(generated_id).starts_with("target_")

	var found = TargetDiscoveryService.get_target_by_id(generated_id)
	assert_object(found).is_same(target)

func test_subtype_deterministic_ids() -> void:
	var unit1 = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit1._ready()
	print("DEBUG: unit1 ID = '%s'" % unit1.get_target_id())
	assert_str(unit1.get_target_id()).is_equal("unit_1")

	var loot1 = auto_free(load("res://Gameplay/targets/loot.gd").new())
	loot1._ready()
	print("DEBUG: loot1 ID = '%s'" % loot1.get_target_id())
	assert_str(loot1.get_target_id()).is_equal("loot_1")

	var unit2 = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit2._ready()
	print("DEBUG: unit2 ID = '%s'" % unit2.get_target_id())
	assert_str(unit2.get_target_id()).is_equal("unit_2")

func test_willpower_standardization() -> void:
	var unit = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit.max_willpower = 50
	assert_int(unit.get_max_willpower()).is_equal(50)

func test_registry_clear() -> void:
	var target = auto_free(load("res://Gameplay/targets/target.gd").new())
	target._ready()
	var tid = target.get_target_id()

	TargetDiscoveryService.clear_registry()
	assert_object(TargetDiscoveryService.get_target_by_id(tid)).is_null()
