extends GdUnitTestSuite

func _make_unit(faction: Unit.Faction) -> Unit:
	var unit: Unit = auto_free(Unit.new())
	unit.faction = faction
	unit._ready() # Initialize components
	return unit

func test_neutral_handles_attack_from_player() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	var attacker := _make_unit(GameConstants.Faction.PLAYER)
	neutral.loyalty.handle_attack_from(attacker)
	assert_int(neutral.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.ENEMY)

func test_neutral_persuasion_changes_loyalty() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	neutral.neutral_can_be_persuaded = true
	neutral.loyalty.apply_persuasion(GameConstants.Faction.PLAYER)
	assert_int(neutral.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.PLAYER)

func test_reset_neutral_loyalty_clears_alignment() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	neutral.neutral_can_be_persuaded = true
	neutral.loyalty.apply_persuasion(GameConstants.Faction.ENEMY)
	neutral.loyalty.reset_neutral_loyalty()
	assert_int(neutral.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.NEUTRAL)

func test_rally_spreads_loyalty_to_targets() -> void:
	var leader := _make_unit(GameConstants.Faction.NEUTRAL)
	leader.neutral_can_rally_allies = true
	var follower := _make_unit(GameConstants.Faction.NEUTRAL)
	follower.neutral_can_be_persuaded = true
	leader.loyalty.set_neutral_loyalty(GameConstants.Faction.PLAYER, true, [follower])
	assert_int(follower.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.PLAYER)

func test_unit_manager_reset_all_neutral_loyalties() -> void:
	var manager: UnitManager = auto_free(UnitManager.new())
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	neutral.neutral_can_be_persuaded = true
	neutral.loyalty.apply_persuasion(GameConstants.Faction.PLAYER)
	neutral.set_unit_manager(manager)
	manager.add_unit(neutral, Vector2i.ZERO, false)
	manager.reset_all_neutral_loyalties()
	assert_int(neutral.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.NEUTRAL)
