# test_target_interaction_handler_applies_willpower.gd
extends GdUnitTestSuite

func test_interaction_applies_damage_to_passed_target() -> void:
	var unit: Unit = auto_free(Unit.new())
	var combat_system: CombatSystem = auto_free(CombatSystem.new())
	unit.set_combat_system(combat_system)

	var handler: TargetInteractionHandler = TargetInteractionHandler.new(unit)

	var intended_target: Loot = auto_free(Loot.new())
	var stale_target: Loot = auto_free(Loot.new())

	intended_target.set_willpower(10)
	stale_target.set_willpower(10)

	var params: CombatResult = CombatResult.new()
	params.attacker = unit
	params.defender = stale_target # Simulate stale/mismatched forecast payload
	params.damage = 4
	params.type = GameConstants.Activity.GATHER

	var success: bool = handler.interact(intended_target, params)
	assert_bool(success).is_true()
	assert_int(intended_target.get_current_willpower()).is_equal(6)
	assert_int(stale_target.get_current_willpower()).is_equal(10)
