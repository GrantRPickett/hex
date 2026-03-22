extends GdUnitTestSuite

func _make_unit(faction: GameConstants.Faction, _coord: Vector2i = Vector2i.ZERO) -> Unit:
	var unit: Unit = auto_free(Unit.new())
	unit.faction = faction
	unit.unit_name = "Unit_" + str(faction)
	unit.movement = auto_free(UnitMovementBehavior.new())
	unit._ready()
	return unit

func test_convince_action_generated_for_nearby_neutral() -> void:
	var player := _make_unit(GameConstants.Faction.PLAYER, Vector2i(0, 0))
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL, Vector2i(1, 0)) # Adjacent
	
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	unit_manager.add_unit(player, Vector2i(0, 0), true)
	unit_manager.add_unit(neutral, Vector2i(1, 0), false)
	
	# Mock reach state
	var reach_state := ReachableState.new()
	reach_state.coords = [Vector2i(0, 0)]
	reach_state.lookup = {Vector2i(0, 0): 0}
	reach_state.unit_index = 0
	
	var calculator := CombatActionCalculator.new()
	var actions: Array[UnitAction] = []
	calculator.append_combat_actions(actions, player, unit_manager, reach_state, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	
	var convince_action: UnitAction = null
	for a in actions:
		if a.type == UnitAction.Type.CONVINCE:
			convince_action = a
			break
	
	assert_object(convince_action).is_not_null()
	assert_bool(convince_action.available).is_true()
	assert_array(convince_action.targets).contains([neutral])

func test_convince_action_not_generated_for_static_neutral() -> void:
	var player := _make_unit(GameConstants.Faction.PLAYER, Vector2i(0, 0))
	var neutral := _make_unit(GameConstants.Faction.NEUTRAL, Vector2i(1, 0))
	neutral.loyalty_type = GameConstants.Faction.STATIC
	
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	unit_manager.add_unit(player, Vector2i(0, 0), true)
	unit_manager.add_unit(neutral, Vector2i(1, 0), false)
	
	var reach_state := ReachableState.new()
	reach_state.coords = [Vector2i(0, 0)]
	reach_state.lookup = {Vector2i(0, 0): 0}
	
	var calculator := CombatActionCalculator.new()
	var actions: Array[UnitAction] = []
	calculator.append_combat_actions(actions, player, unit_manager, reach_state, TileSet.TILE_OFFSET_AXIS_VERTICAL)
	
	var convince_action: UnitAction = null
	for a in actions:
		if a.type == UnitAction.Type.CONVINCE:
			convince_action = a
			break
	
	assert_object(convince_action).is_null()
