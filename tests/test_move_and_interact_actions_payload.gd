# test_move_and_interact_actions_payload.gd
extends GdUnitTestSuite

func test_build_specialized_action_payload() -> void:
	var actor := Unit.new()
	var unit_manager := UnitManager.new()
	actor.set_unit_manager(unit_manager)

	var mesh := TileMapLayer.new()
	var tset := TileSet.new()
	mesh.tile_set = tset
	actor.grid_map = mesh

	var target := Loot.new()
	var move_coord := Vector2i(1, 2)
	var move_cost := 5
	var interaction_type := "loot"
	var action_id := "test_action"

	var action := MoveAndInteractProvider.build_specialized_action(actor, target, move_coord, move_cost, interaction_type, action_id)

	assert_int(action.type).is_equal(GameConstants.ActionType.MOVE_AND_INTERACT)
	assert_dict(action.command_payload).contains_key(GameConstants.Payload.TARGET_MOVE_COORD)
	assert_array(action.command_payload[GameConstants.Payload.TARGET_MOVE_COORD]).is_equal(move_coord)

	# Test PlayerActionManager with null move_data (distance 0)
	var base_action := PlayerAction.new(GameConstants.ActionType.GATHER)
	base_action.actor = actor
	var actor_pos = actor.get_grid_location()
	var action_from_mgr := PlayerActionManager.create_move_and_interact_action(base_action, target, {}, unit_manager)

	assert_int(action_from_mgr.move_cost).is_equal(0)
	assert_dict(action_from_mgr.command_payload).contains_key(GameConstants.Payload.TARGET_MOVE_COORD)
	assert_array(action_from_mgr.command_payload[GameConstants.Payload.TARGET_MOVE_COORD]).is_equal(actor_pos)

	# Cleanup
	actor.free()
	unit_manager.free()
	mesh.free()
	tset.free()
	target.free()

func test_create_skill_action_payload() -> void:
	# Similar check for _create_skill_action in PlayerActionManager
	# This requires more setup (Skill, BaseAction, etc.)
	pass
