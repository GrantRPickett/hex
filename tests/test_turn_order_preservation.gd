extends GdUnitTestSuite

var _turn_controller: TurnController
var _unit_manager: UnitManager

func before_test() -> void:
	_turn_controller = auto_free(TurnController.new())
	_turn_controller.reset()
	_unit_manager = auto_free(UnitManager.new())
	
	add_child(_turn_controller)
	add_child(_unit_manager)
	
	var state := GameState.new({}, [])
	state.unit_manager = _unit_manager
	var config := GameSessionBuilder.Config.new()
	_turn_controller.setup(state, config)

func test_preserve_queue_state_alternates_new_units() -> void:
	# 1. Setup initial units
	# Disconnect signals briefly to avoid intermediate re-builds during setup
	_unit_manager.unit_added.disconnect(_turn_controller._on_unit_added)
	
	var p1 = auto_free(Unit.new())
	p1.unit_name = "P1"
	p1.faction = GameConstants.Faction.PLAYER
	# Mock movement component to avoid crash
	p1.add_child(auto_free(Node.new())) # Placeholder for movement check if needed, but Unit has it by default from Factory
	p1.movement = auto_free(UnitMovementBehavior.new())
	
	var e1 = auto_free(Unit.new())
	e1.unit_name = "E1"
	e1.faction = GameConstants.Faction.ENEMY
	e1.movement = auto_free(UnitMovementBehavior.new())
	
	_unit_manager.add_unit(p1, Vector2i(0, 0), true) # Index 0
	_unit_manager.add_unit(e1, Vector2i(1, 1), false) # Index 1
	
	# Reconnect and build initial roster
	_unit_manager.unit_added.connect(_turn_controller._on_unit_added)
	_turn_controller.rebuild_turn_roster()
	
	# Initial queue: [0, 1] (P1, E1)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([0, 1])
	
	# 2. Simulate P1 taking its turn
	_turn_controller.complete_turn()
	# Queue now: [1] (E1)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([1])
	assert_array(_turn_controller._completed_units_this_round).contains([0])
	
	# 3. Spawn NEW units mid-round
	var p2 = auto_free(Unit.new())
	p2.unit_name = "P2"
	p2.faction = GameConstants.Faction.PLAYER
	p2.movement = auto_free(UnitMovementBehavior.new())
	
	var e2 = auto_free(Unit.new())
	e2.unit_name = "E2"
	e2.faction = GameConstants.Faction.ENEMY
	e2.movement = auto_free(UnitMovementBehavior.new())
	
	# These will trigger rebuild_turn_roster(true) automatically via signals
	_unit_manager.add_unit(p2, Vector2i(0, 1), true) # Index 2
	_unit_manager.add_unit(e2, Vector2i(1, 2), false) # Index 3
	
	# Final expected behavior:
	# Queue should be [1, 2, 3] (E1, P2, E2)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([1, 2, 3])
	
	# 4. Verify it continues alternating if we add even MORE units
	var p3 = auto_free(Unit.new())
	p3.unit_name = "P3"
	p3.faction = GameConstants.Faction.PLAYER
	p3.movement = auto_free(UnitMovementBehavior.new())
	
	_unit_manager.add_unit(p3, Vector2i(0, 2), true) # Index 4
	
	# Queue was [1, 2, 3]. Last unit is 3 (E2).
	# Next added should be from PLAYER (P3).
	# Final queue: [1, 2, 3, 4] (E-P-E-P)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([1, 2, 3, 4])
