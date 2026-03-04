extends GdUnitTestSuite

# Tests for UnitInteractionHandler and UnitCombatBehavior
# Covering: interact, loot, work_on_task, attack, aid_ally

class FakeCombatSystem extends CombatSystem:
	var attacked_target: Unit = null
	func execute_combat(_attacker: Unit, defender: Unit, _attr: int) -> Dictionary:
		attacked_target = defender
		return {}

func _make_unit(faction: Unit.Faction, coord: Vector2i) -> Unit:
	var u: Unit = Unit.new()
	u.faction = faction
	u.movement_range_cache_template = null
	var ap = ActionPointsComponent.new()
	u.action_points_template = ap
	u.res = ap
	u.max_willpower = 10
	u.willpower = 10
	add_child(u) # initialize components
	u.set_external_grid_coord(coord)
	return u

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# UnitInteractionHandler
# ---------------------------------------------------------------------------

func test_interaction_handler_interact_routes_to_units() -> void:
	var mgr := UnitManager.new()
	var u1: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 0))
	var u2: Unit = _make_unit(Unit.Faction.ENEMY, Vector2i(0, 1))

	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)
	u1.set_unit_manager(mgr)

	var cs := FakeCombatSystem.new()
	u1.set_combat_system(cs)

	var handler: UnitInteractionHandler = u1.interaction
	handler.interact(u2)

	assert_object(cs.attacked_target).is_equal(u2)
	assert_bool(u1.res.has_action_available()).is_false()

	mgr.queue_free()

func test_interaction_handler_interact_aids_allies() -> void:
	var mgr := UnitManager.new()
	var u1: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 0))
	var u2: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 1))
	u2.willpower = 5

	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)
	u1.set_unit_manager(mgr)

	var handler: UnitInteractionHandler = u1.interaction
	handler.interact(u2)

	assert_bool(u2.willpower > 5).is_true()
	assert_bool(u1.res.has_action_available()).is_false()

	mgr.queue_free()

func test_combat_behavior_attack_fails_if_no_action() -> void:
	var mgr := UnitManager.new()
	var u1: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 0))
	var u2: Unit = _make_unit(Unit.Faction.ENEMY, Vector2i(0, 1))
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)
	u1.set_unit_manager(mgr)
	var cs := FakeCombatSystem.new()
	u1.set_combat_system(cs)

	u1.res.consume_action() # Empty it

	var success := u1.combat.attack(u2)
	assert_bool(success).is_false()
	assert_object(cs.attacked_target).is_null()

	mgr.queue_free()

func test_combat_behavior_attack_fails_if_not_adjacent() -> void:
	var mgr := UnitManager.new()
	var u1: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 0))
	var u2: Unit = _make_unit(Unit.Faction.ENEMY, Vector2i(9, 9))
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(9, 9), false)
	u1.set_unit_manager(mgr)
	var cs := FakeCombatSystem.new()
	u1.set_combat_system(cs)

	var success := u1.combat.attack(u2)
	assert_bool(success).is_false()
	assert_object(cs.attacked_target).is_null()

	mgr.queue_free()

func test_combat_behavior_aid_ally_fails_if_not_adjacent() -> void:
	var mgr := UnitManager.new()
	var u1: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(0, 0))
	var u2: Unit = _make_unit(Unit.Faction.PLAYER, Vector2i(9, 9))
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(9, 9), false)
	u1.set_unit_manager(mgr)

	var success := u1.combat.aid_ally(u2)
	assert_bool(success).is_false()

	mgr.queue_free()
