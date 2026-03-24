extends GdUnitTestSuite

func test_create_move_and_interact_action_payload() -> void:
    var unit_manager = auto_free(UnitManager.new())
    var unit = auto_free(Unit.new())
    unit.unit_name = "TestUnit"
    
    # Mocking unit_manager behavior
    # We need to add them to a tree or mock if they use get_tree()
    # But for this simple test, let's see if we can just call the static method
    
    var base_action = PlayerAction.new(GameConstants.ActionType.ATTACK)
    base_action.command_id = GameConstants.Commands.CommandID.ATTACK
    
    var target = auto_free(Target.new())
    var target_coord = Vector2i(5, 5)
    target.set_external_grid_coord(target_coord)
    
    var move_data = {
        target: {"coord": Vector2i(4, 5), "cost": 2}
    }
    
    # We need to mock unit_manager.get_unit_index
    # Since it's a real class, we might need to set up some internal state
    
    var final_action = PlayerActionManager.create_move_and_interact_action(
        base_action, target, move_data, unit_manager
    )
    
    assert_that(final_action.type).is_equal(GameConstants.ActionType.MOVE_AND_INTERACT)
    assert_that(final_action.move_cost).is_equal(2)
    assert_dict(final_action.command_payload).contains_keys([GameConstants.Payload.TARGET_MOVE_COORD])
    assert_that(final_action.command_payload[GameConstants.Payload.TARGET_MOVE_COORD]).is_equal(Vector2i(4, 5))
