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
	var p1 = auto_free(Unit.new())
	p1.unit_name = "P1"
	p1.faction = GameConstants.Faction.PLAYER
	p1.willpower = 10
	
	var e1 = auto_free(Unit.new())
	e1.unit_name = "E1"
	e1.faction = GameConstants.Faction.ENEMY
	e1.willpower = 10
	
	_unit_manager.add_unit(p1, Vector2i(0, 0), true) # Index 0
	_unit_manager.add_unit(e1, Vector2i(1, 1), false) # Index 1
	
	_turn_controller.rebuild_turn_roster()
	# Initial queue: [0, 1] (P1, E1)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([0, 1])
	
	# 2. Simulate P1 taking its turn
	_turn_controller.complete_turn()
	# Queue now: [1] (E1)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([1])
	
	# 3. Spawn NEW units mid-round
	var p2 = auto_free(Unit.new())
	p2.unit_name = "P2"
	p2.faction = GameConstants.Faction.PLAYER
	p2.willpower = 10
	
	var e2 = auto_free(Unit.new())
	e2.unit_name = "E2"
	e2.faction = GameConstants.Faction.ENEMY
	e2.willpower = 10
	
	_unit_manager.add_unit(p2, Vector2i(0, 1), true) # Index 2
	_unit_manager.add_unit(e2, Vector2i(1, 2), false) # Index 3
	
	# 4. Rebuild roster with preserve_state = true
	_turn_controller.rebuild_turn_roster(true)
	
	# Expected behavior:
	# Last unit in queue was P1 (Wait, P1 was completed, and E1 is now the NEXT unit in the queue).
	# Actually, the queue has [1] (E1).
	# The last unit in the queue is E1 (Enemy).
	# So the next unit added should be from PLAYER (P2), then ENEMY (E2).
	# Final queue should be: [1, 2, 3] (E1, P2, E2)
	# This IS alternating: E-P-E
	
	var final_queue = _turn_controller.get_turn_queue()
	assert_array(final_queue).contains_exactly([1, 2, 3])
	
	# 5. Verify it continues alternating if we add even MORE units
	var p3 = auto_free(Unit.new())
	p3.unit_name = "P3"
	p3.faction = GameConstants.Faction.PLAYER
	p3.willpower = 10
	
	_unit_manager.add_unit(p3, Vector2i(0, 2), true) # Index 4
	_turn_controller.rebuild_turn_roster(true)
	
	# Queue was [1, 2, 3]. Last unit is 3 (E2).
	# Next added should be from PLAYER (P3).
	# Final queue: [1, 2, 3, 4] (E-P-E-P)
	assert_array(_turn_controller.get_turn_queue()).contains_exactly([1, 2, 3, 4])
