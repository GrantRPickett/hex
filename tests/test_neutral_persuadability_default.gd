extends GdUnitTestSuite

func _make_unit(faction: GameConstants.Faction) -> Unit:
	var unit: Unit = auto_free(Unit.new())
	unit.faction = faction
	# Mock movement component to avoid issues if any code expects it
	unit.movement = auto_free(UnitMovementBehavior.new())
	unit._ready() # Initialize components
	return unit

func test_neutral_is_persuadable_by_default() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	
	assert_bool(neutral.neutral_can_be_persuaded).is_true()
	assert_bool(TargetDiscoveryService.is_convincable(neutral)).is_true()

func test_static_neutral_is_not_persuadable_by_default() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	neutral.loyalty_type = GameConstants.Faction.STATIC
	
	# Even if flag is true, is_convincable should return false for static
	assert_bool(neutral.neutral_can_be_persuaded).is_true()
	assert_bool(TargetDiscoveryService.is_convincable(neutral)).is_false()

func test_aligned_neutral_is_not_persuadable() -> void:
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL)
	neutral.loyalty.set_neutral_loyalty(GameConstants.Faction.PLAYER)
	
	assert_int(neutral.loyalty.neutral_loyalty).is_equal(GameConstants.Faction.PLAYER)
	# Once joined a side, should not be convincable anymore
	assert_bool(TargetDiscoveryService.is_convincable(neutral)).is_false()

func test_player_is_not_persuadable() -> void:
	var player := _make_unit(GameConstants.Faction.PLAYER)
	
	# Flag might be true by default in Unit.gd, but TargetDiscoveryService filters by faction
	assert_bool(TargetDiscoveryService.is_convincable(player)).is_false()
