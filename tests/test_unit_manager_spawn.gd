extends GdUnitTestSuite

func test_add_unit_emits_spawn_signal() -> void:
	var manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = auto_free(Unit.new())
	var emitted := [false]
	manager.unit_spawn_requested.connect(func(new_unit):
		if new_unit == unit:
			emitted[0] = true
	)
	manager.add_unit(unit, Vector2i.ZERO, true)
	assert_bool(emitted[0]).is_true()
