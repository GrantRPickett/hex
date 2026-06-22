extends GdUnitTestSuite

# Dependencies
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
	_unit_manager.free()
	_turn_controller.free()

func test_queue_patches_on_unit_removal() -> void:
	# 1. Setup 3 units
	var u1 = auto_free(UnitScene.new())
	var u2 = auto_free(UnitScene.new())
	var u3 = auto_free(UnitScene.new())
	
	_unit_manager.add_unit(u1, Vector2i(1, 1), true)
	_unit_manager.add_unit(u2, Vector2i(2, 2), true)
	_unit_manager.add_unit(u3, Vector2i(3, 3), true)
	
	# 2. Build initial queue [0, 1, 2]
	_turn_controller._turn_queue = [0, 1, 2]
	
	# 3. Remove unit at index 1 (u2)
	_unit_manager.remove_unit(u2)
	
	# 4. Verify queue is now [0, 1] (u1 at 0, u3 at 1)
	assert_array(_turn_controller.get_turn_queue()).is_equal([0, 1])
	
	# 5. Verify current unit index if it was higher
	_turn_controller._current_unit_index = 2 # Was pointing to u3
	_unit_manager.remove_unit(u1) # removes old index 0, u3 was index 1 (new index), now becomes 0
	# Wait, if we remove index 0, queue [0, 1] becomes [0] (original u3)
	assert_array(_turn_controller.get_turn_queue()).is_equal([0])
