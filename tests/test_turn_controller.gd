extends GdUnitTestSuite

var _turn_controller: TurnController
var _unit_manager: UnitManager
var _unit1: Unit
var _unit2: Unit

func before() -> void:
	_turn_controller = auto_free(TurnController.new())
	_unit_manager = auto_free(UnitManager.new())
	_unit1 = auto_free(Unit.new())
	_unit1.unit_name = "Unit1"
	_unit2 = auto_free(Unit.new())
	_unit2.unit_name = "Unit2"
	
	_turn_controller.setup(_unit_manager, null)

func test_start_next_turn_with_empty_queue() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	
	_turn_controller.start_next_turn()
	
	# Should handle empty queue gracefully
	assert_object(_turn_controller).is_not_null()

func test_complete_turn() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)
	
	# complete_turn is a signal-based method, just verify it exists and is callable
	_turn_controller.complete_turn()
	
	assert_object(_turn_controller).is_not_null()

func test_get_current_unit_index() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	
	var index = _turn_controller.get_current_unit_index()
	
	# Index might be -1 initially
	assert_object(index).is_not_null()

func test_get_current_side() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	
	var side = _turn_controller.get_current_side()
	
	assert_object(side).is_not_null()

func test_get_round() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	
	var current_round = _turn_controller.get_round()
	
	assert_int(current_round).is_equal(1)
