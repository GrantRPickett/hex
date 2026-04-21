# test_move_and_interact_actions_payload.gd
extends GdUnitTestSuite

func test_build_specialized_action_payload() -> void:
	var actor := auto_free(Unit.new())
	var unit_manager := auto_free(UnitManager.new())
	actor.set_unit_manager(unit_manager)

	var mesh := auto_free(TileMapLayer.new())
	var tset := TileSet.new()
	mesh.tile_set = tset
	actor.grid_map = mesh

	var target := auto_free(Loot.new())
	var move_coord := Vector2i(1, 2)
	var move_cost := 5
	var interaction_type := "loot"
	var action_id := "test_action"

	var action := MoveAndInteractProvider.build_specialized_action(actor, target, move_coord, move_cost, interaction_type, action_id)

	assert_int(action.type).is_equal(GameConstants.ActionType.MOVE_AND_INTERACT)
	assert_dict(action.command_payload).contains_keys(GameConstants.Payload.TARGET_MOVE_COORD)
	assert_bool(action.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] == move_coord).is_true()

	# Test PlayerActionManager with null move_data (distance 0)
	var base_action := PlayerAction.new(GameConstants.ActionType.GATHER)
	base_action.actor = actor
	var actor_pos = actor.get_grid_location()
	var action_from_mgr := PlayerActionManager.create_move_and_interact_action(base_action, target, {}, unit_manager)

	assert_int(action_from_mgr.move_cost).is_equal(0)
	assert_dict(action_from_mgr.command_payload).contains_keys(GameConstants.Payload.TARGET_MOVE_COORD)
	assert_bool(action_from_mgr.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] == actor_pos).is_true()

func test_combat_result_hydration() -> void:
	var actor := auto_free(Unit.new())
	var target := auto_free(Loot.new())
	var unit_manager := auto_free(UnitManager.new())

	# Mock registry
	TargetDiscoveryService.register_target(target)

	var payload = {
		GameConstants.Payload.UNIT_INDEX: 0,
		"target_id": target.id,
		GameConstants.Payload.FORECAST_RESULTS: {
			"damage": 10,
			"type": "gather"
		}
	}

	var context = GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: unit_manager
	})

	# Stub unit manager
	var mock_unit_manager = mock(UnitManager)
	do_return(actor).on(mock_unit_manager).get_unit(0)
	context.unit_manager = mock_unit_manager

	var res = CombatResult.from_payload(payload, context)

	assert_object(res).is_not_null()
	assert_object(res.attacker).is_equal(actor)
	assert_object(res.defender).is_equal(target)
	assert_int(res.damage).is_equal(10)
	assert_str(res.type).is_equal("gather")

	# Cleanup
	TargetDiscoveryService.unregister_target(target)
