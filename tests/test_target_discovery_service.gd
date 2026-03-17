extends GdUnitTestSuite

func test_discover_nearby_all_types() -> void:
	var um := auto_free(UnitManager.new())
	var lm := auto_free(LootManager.new())
	var tm := auto_free(TaskManager.new())
	
	var center := Vector2i(0, 0)
	var radius := 5.0
	
	var unit := auto_free(Unit.new())
	um.add_unit(unit, center)
	
	var loot := auto_free(Loot.new())
	lm.add_loot(loot, Vector2i(1, 1))
	
	var context := {
		"unit_manager": um,
		"loot_manager": lm,
		"task_manager": tm
	}
	
	var results := TargetDiscoveryService.discover_nearby(center, radius, TargetDiscoveryService.ALL, context)
	
	assert_dict(results).has_entry(TargetDiscoveryService.UNIT)
	assert_dict(results).has_entry(TargetDiscoveryService.LOOT)
	assert_dict(results).has_entry(TargetDiscoveryService.TASK)
	assert_dict(results).has_entry(TargetDiscoveryService.LOCATION)

func test_discover_nearby_specific_type() -> void:
	var um := auto_free(UnitManager.new())
	var context := {"unit_manager": um}
	
	var results := TargetDiscoveryService.discover_nearby(Vector2i(0, 0), 10.0, [TargetDiscoveryService.UNIT], context)
	assert_dict(results).has_entry(TargetDiscoveryService.UNIT)
	assert_dict(results).does_not_have_entry(TargetDiscoveryService.LOOT)

func test_discover_reachable() -> void:
	var um := auto_free(UnitManager.new())
	var unit := auto_free(Unit.new())
	um.add_unit(unit, Vector2i(1, 1))
	
	var reach := ReachableState.new()
	reach.lookup = {Vector2i(1, 1): 0.0}
	
	var context := {"unit_manager": um}
	
	var results := TargetDiscoveryService.discover_reachable(reach, [TargetDiscoveryService.UNIT], context)
	var units: Array = results[TargetDiscoveryService.UNIT]
	assert_int(units.size()).is_equal(1)
	assert_object(units[0]).is_same(unit)
