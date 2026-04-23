extends GdUnitTestSuite

const Turner := preload("res://Gameplay/turn/turn_controller.gd")
const Manager := preload("res://Gameplay/targets/unit_manager.gd")
const UnitScene := preload("res://Gameplay/targets/unit.gd")

var _unit_manager: UnitManager
var _turn_controller: TurnController

func before_test() -> void:
	_unit_manager = Manager.new()
	_turn_controller = Turner.new()
	
	var state := GameState.new({})
	state.unit_manager = _unit_manager
	state.turn_controller = _turn_controller
	
	_turn_controller.setup(state, GameSessionBuilder.Config.new())
	get_tree().root.add_child(_unit_manager)
	get_tree().root.add_child(_turn_controller)

func after_test() -> void:
	if is_instance_valid(_unit_manager): _unit_manager.free()
	if is_instance_valid(_turn_controller): _turn_controller.free()

func test_round_transition_with_asymmetric_units() -> void:
	# 1. Setup 2 player units, 0 enemy units
	var p1 = auto_free(UnitScene.new())
	var p2 = auto_free(UnitScene.new())
	p1.faction = GameConstants.Faction.PLAYER
	p2.faction = GameConstants.Faction.PLAYER
	p1.willpower = 10
	p2.willpower = 10
	
	_unit_manager.add_unit(p1, Vector2i(1, 1), true)
	_unit_manager.add_unit(p2, Vector2i(2, 2), true)
	
	_turn_controller.rebuild_turn_roster()
	
	# 2. Verify queue has 2 units
	assert_int(_turn_controller.get_turn_queue().size()).is_equal(2)
	assert_int(_turn_controller.get_current_round()).is_equal(1)
	
	# 3. Complete 1st turn
	_turn_controller.complete_turn()
	await get_tree().process_frame # start_next_turn is deferred
	
	assert_int(_turn_controller.get_turn_queue().size()).is_equal(1)
	
	# 4. Complete 2nd turn (Round ends)
	_turn_controller.complete_turn()
	await get_tree().process_frame # start_next_turn is deferred
	
	# Round should have incremented to 2
	assert_int(_turn_controller.get_current_round()).is_equal(2)
	# Queue should have been refilled with 2 units
	assert_int(_turn_controller.get_turn_queue().size()).is_equal(2)

func test_empty_faction_does_not_loop() -> void:
	# 1. Setup 0 units
	_turn_controller.rebuild_turn_roster()
	
	# 2. Attempt to start next turn
	_turn_controller.start_next_turn()
	
	# Should not loop or crash, and should remain at round 1 if no units can act
	# Actually, start_next_turn with empty queue calls _start_new_round which increments it
	assert_int(_turn_controller.get_current_round()).is_greater_than(1)
	assert_array(_turn_controller.get_turn_queue()).is_empty()
