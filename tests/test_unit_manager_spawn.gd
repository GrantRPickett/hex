extends GdUnitTestSuite

func test_add_unit_emits_spawn_signal() -> void:
	var manager := auto_free(UnitManager.new())
	var unit := auto_free(Unit.new())
	var emitted := false
	manager.unit_spawn_requested.connect(func(new_unit):
		if new_unit == unit:
			emitted = true
	)
	manager.add_unit(unit, Vector2i.ZERO, true)
	assert_bool(emitted).is_true()
