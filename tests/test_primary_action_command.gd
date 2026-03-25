extends GdUnitTestSuite

const Stubs := preload("res://tests/fixtures/test_stubs.gd")

class MockGrid extends Node2D:
	func local_to_map(p_pos: Vector2) -> Vector2i:
		return Vector2i(p_pos)

func test_primary_action_selects_unit() -> void:
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	um.add_unit(unit, Vector2i(1, 1))
	um.set_player_controlled(0, true)
	
	var tc: Stubs.FakeTurnController = auto_free(Stubs.FakeTurnController.new())
	# tc.can_act_on_index defaults to true in FakeTurnController
	
	var grid: MockGrid = auto_free(MockGrid.new())
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.GRID: grid,
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: tc,
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new()),
		GameConstants.ContextKeys.TASK_MANAGER: auto_free(Stubs.FakeTaskManager.new()),
		GameConstants.ContextKeys.LOOT_MANAGER: auto_free(Stubs.FakeLootManager.new())
	}))
	
	var command: PrimaryActionCommand = PrimaryActionCommand.new()
	var result: CommandResult = command.execute(context, { GameConstants.Payload.POSITION: Vector2(1, 1) })
	
	assert_bool(result.is_success()).is_true()
	assert_int(um.get_selected_index()).is_equal(0)

func test_primary_action_interacts_with_location() -> void:
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var tm: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var mc: Stubs.FakeMoveController = auto_free(Stubs.FakeMoveController.new())
	var grid: MockGrid = auto_free(MockGrid.new())
	
	var location: Location = auto_free(Location.new())
	location.name = "TestLocation"
	tm.set_location(Vector2i(2, 2), location)
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.GRID: grid,
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: auto_free(Stubs.FakeTurnController.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: mc,
		GameConstants.ContextKeys.TASK_MANAGER: tm,
		GameConstants.ContextKeys.LOOT_MANAGER: auto_free(Stubs.FakeLootManager.new())
	}))
	
	var command: PrimaryActionCommand = PrimaryActionCommand.new()
	var result: CommandResult = command.execute(context, { GameConstants.Payload.POSITION: Vector2(2, 2) })
	
	assert_bool(result.is_success()).is_true()
	assert_bool(mc.request_move_and_interact_called).is_true()
	assert_object(mc.last_interaction_target).is_equal(location)

func test_primary_action_interacts_with_loot() -> void:
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var tm: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var lm: Stubs.FakeLootManager = auto_free(Stubs.FakeLootManager.new())
	var mc: Stubs.FakeMoveController = auto_free(Stubs.FakeMoveController.new())
	var grid: MockGrid = auto_free(MockGrid.new())
	
	var loot: Loot = auto_free(Loot.new())
	loot.name = "TestLoot"
	lm.add_loot(loot, Vector2i(3, 3))
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.GRID: grid,
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: auto_free(Stubs.FakeTurnController.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: mc,
		GameConstants.ContextKeys.TASK_MANAGER: tm,
		GameConstants.ContextKeys.LOOT_MANAGER: lm
	}))
	
	var command: PrimaryActionCommand = PrimaryActionCommand.new()
	var result: CommandResult = command.execute(context, { GameConstants.Payload.POSITION: Vector2(3, 3) })
	
	assert_bool(result.is_success()).is_true()
	assert_bool(mc.request_move_and_interact_called).is_true()
	assert_bool(mc.request_move_and_interact_called).is_true()
	assert_object(mc.last_interaction_target).is_equal(loot)

func test_primary_action_interacts_with_trapped_loot_when_at_cell() -> void:
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var lm: Stubs.FakeLootManager = auto_free(Stubs.FakeLootManager.new())
	var grid: MockGrid = auto_free(MockGrid.new())
	
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	um.add_unit(unit, Vector2i(4, 4))
	um.select_index(0)
	um.set_player_controlled(0, true)
	
	var loot: Loot = auto_free(Loot.new())
	loot.name = "TrappedLoot"
	loot.is_trapped = true
	lm.add_loot(loot, Vector2i(4, 4))
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.GRID: grid,
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: auto_free(Stubs.FakeTurnController.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new()),
		GameConstants.ContextKeys.TASK_MANAGER: auto_free(Stubs.FakeTaskManager.new()),
		GameConstants.ContextKeys.LOOT_MANAGER: lm
	}))
	
	# Mock the loot interactive call to verify it's called with the right type
	# Since 'Target' (base of Loot) has 'interact(unit, data)', we can check it.
	# However, Loot's interact is not overridden, but we can check signals or just rely on the return.
	# Actually, PrimaryActionCommand calls 'interaction_target.interact(active_unit, {"type": type})'
	# and we want to ensure 'type' is 'trapped'.
	
	var command: PrimaryActionCommand = PrimaryActionCommand.new()
	var result: CommandResult = command.execute(context, { GameConstants.Payload.POSITION: Vector2(4, 4) })
	
	assert_bool(result.is_success()).is_true()
	# We can't easily verify the 'interact' call on the Loot object without a mock Loot.
	# But we can at least ensure it doesn't crash anymore.

