extends GdUnitTestSuite

func test_target_returns_external_grid_coord() -> void:
	var target: Target = auto_free(Target.new())
	target.position = Vector2(256, 256)
	target.set_external_grid_coord(Vector2i(3, 4))
	assert_that(target.get_grid_location()).is_equal(Vector2i(3, 4))

func test_distance_to_target_uses_external_coords() -> void:
	var manager: UnitManager = auto_free(UnitManager.new())
	var attacker: Unit = auto_free(Unit.new())
	attacker._ready()
	attacker.set_unit_manager(manager)
	manager.add_unit(attacker, Vector2i.ZERO, true)
	var defender: Unit = auto_free(Unit.new())
	defender._ready()
	defender.set_unit_manager(manager)
	manager.add_unit(defender, Vector2i(1, 0), false)
	attacker.position = Vector2(1024, 0)
	defender.position = Vector2(-1024, 0)
	assert_int(attacker.distance_to_target(defender)).is_equal(1)

func test_location_interaction_respects_external_coord() -> void:
	var manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.set_unit_manager(manager)
	manager.add_unit(unit, Vector2i.ZERO, true)
	unit.position = Vector2(640, 0)
	var loc: Location = auto_free(Location.new())
	loc._ready()
	loc.position = Vector2(-640, 0)
	loc.set_external_grid_coord(Vector2i.ZERO)
	assert_bool(loc.can_be_worked_on_by(unit)).is_true()

func test_target_clear_external_coord_resets_state() -> void:
	var target: Target = auto_free(Target.new())
	target.set_external_grid_coord(Vector2i(5, 5))
	assert_bool(target.has_external_grid_coord()).is_true()
	target.clear_external_grid_coord()
	assert_bool(target.has_external_grid_coord()).is_false()

func test_loot_can_be_looted_by_uses_external_coord() -> void:
	var manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.set_unit_manager(manager)
	manager.add_unit(unit, Vector2i.ZERO, true)
	var loot: Loot = auto_free(Loot.new())
	loot.set_external_grid_coord(Vector2i.ZERO)
	assert_bool(loot.can_be_looted_by(unit)).is_true()
