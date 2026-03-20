extends GdUnitTestSuite
# Test suite for action commands: AttackUnitCommand, AidAllyCommand, ExploreCommand, LootCommand

const Stubs := preload("res://tests/fixtures/test_stubs.gd")

class MockUnit extends Stubs.FakeUnit:
	var last_attack_target: Unit
	var last_attack_attribute_idx: int = -1
	var aid_happened_with: Unit = null

	func attack(target: Unit, pair_idx: int = 0) -> void:
		last_attack_target = target
		last_attack_attribute_idx = pair_idx
		super.attack(target, pair_idx)

	func aid_ally(target: Unit) -> void:
		aid_happened_with = target

	func die() -> void:
		pass

func test_attack_command_execution() -> void:
	var attacker: MockUnit = auto_free(MockUnit.new())
	var target: MockUnit = auto_free(MockUnit.new())
	attacker.unit_name = "Attacker"
	target.unit_name = "Target"
	attacker.faction = GameConstants.Faction.PLAYER
	target.faction = GameConstants.Faction.ENEMY
	target.willpower = 10
	attacker._hostiles = [target]
	
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	um.add_unit(attacker, Vector2i(0, 0)) # index 0
	um.add_unit(target, Vector2i(1, 0)) # index 1
	um.set_player_controlled(0, true)
	um.select_index(0)

	var tc: Stubs.FakeTurnController = auto_free(Stubs.FakeTurnController.new())
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: tc,
		GameConstants.ContextKeys.GRID: auto_free(Node2D.new()),
		GameConstants.ContextKeys.TASK_MANAGER: auto_free(Stubs.FakeTaskManager.new()),
		GameConstants.ContextKeys.LOOT_MANAGER: auto_free(Stubs.FakeLootManager.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new())
	}))

	var payload: Dictionary = {
		GameConstants.Payload.ATTACKER_INDEX: 0,
		GameConstants.Payload.TARGET_INDEX: 1,
		GameConstants.Payload.ATTRIBUTE_INDEX: 1
	}

	var command: AttackUnitCommand = AttackUnitCommand.new()
	var result: CommandResult = command.execute(context, payload)
	
	assert_bool(result.is_success()).is_true()
	assert_object(attacker.last_attack_target).is_equal(target)
	assert_int(attacker.last_attack_attribute_idx).is_equal(1)

func test_aid_ally_command_execution() -> void:
	var aider: MockUnit = auto_free(MockUnit.new())
	var ally: MockUnit = auto_free(MockUnit.new())
	aider.unit_name = "Aider"
	ally.unit_name = "Ally"
	aider.faction = GameConstants.Faction.PLAYER
	ally.faction = GameConstants.Faction.PLAYER
	ally.willpower = 10
	aider._friendly = [ally]
	
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	um.add_unit(aider, Vector2i(0, 0)) # index 0
	um.add_unit(ally, Vector2i(1, 0)) # index 1
	um.set_player_controlled(0, true)
	um.select_index(0)

	var tc: Stubs.FakeTurnController = auto_free(Stubs.FakeTurnController.new())
	
	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TURN_CONTROLLER: tc,
		GameConstants.ContextKeys.GRID: auto_free(Node2D.new()),
		GameConstants.ContextKeys.TASK_MANAGER: auto_free(Stubs.FakeTaskManager.new()),
		GameConstants.ContextKeys.LOOT_MANAGER: auto_free(Stubs.FakeLootManager.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new())
	}))

	var payload: Dictionary = {
		GameConstants.Payload.HELPER_INDEX: 0,
		GameConstants.Payload.TARGET_INDEX: 1,
		GameConstants.Payload.ATTRIBUTE_INDEX: 0
	}

	var command: AidAllyCommand = AidAllyCommand.new()
	var result: CommandResult = command.execute(context, payload)
	
	assert_bool(result.is_success()).is_true()
	assert_object(aider.aid_happened_with).is_equal(ally)

func test_explore_command_execution() -> void:
	var unit: MockUnit = auto_free(MockUnit.new())
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	um.add_unit(unit, Vector2i(1, 1))
	um.set_player_controlled(0, true)
	um.select_index(0)
	
	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	unit.set_task_manager(task_manager)
	
	var location: Location = auto_free(Location.new())
	location.name = "TestLocation"
	location.set_external_grid_coord(Vector2i(1, 1))
	task_manager.set_location(Vector2i(1, 1), location)
	
	var task: Task = auto_free(Task.new())
	task.id = &"task_explore"
	task.event_type = GameConstants.TaskEvents.EXPLORE
	task.target_coord = Vector2i(1, 1)
	task.target_kind = GameConstants.Tasks.KIND_LOCATION
	task.initialize()
	task.target_coord = Vector2i(1, 1)
	task_manager.set_task_for_target(location, task)

	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.TASK_MANAGER: task_manager,
		GameConstants.ContextKeys.GRID: auto_free(Node2D.new()),
		GameConstants.ContextKeys.TURN_CONTROLLER: auto_free(Stubs.FakeTurnController.new()),
		GameConstants.ContextKeys.LOOT_MANAGER: auto_free(Stubs.FakeLootManager.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new())
	}))

	var payload: Dictionary = {
		GameConstants.Payload.TARGET_COORD: Vector2i(1, 1)
	}

	var command: ExploreCommand = ExploreCommand.new()
	var result: CommandResult = command.execute(context, payload)

	assert_bool(result.is_success()).is_true()
	assert_int(task_manager.last_coord.x).is_equal(1)
	assert_int(task_manager.last_coord.y).is_equal(1)

func test_loot_command_execution() -> void:
	var unit: MockUnit = auto_free(MockUnit.new())
	var um: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	um.add_unit(unit, Vector2i(2, 2))
	um.set_player_controlled(0, true)
	um.select_index(0)
	
	var loot_manager: Stubs.FakeLootManager = auto_free(Stubs.FakeLootManager.new())
	var loot: Loot = auto_free(Loot.new())
	loot.name = "TestLoot"
	loot.set_external_grid_coord(Vector2i(2, 2))
	loot_manager.add_loot(loot, Vector2i(2, 2))
	
	var tc: Stubs.FakeTurnController = auto_free(Stubs.FakeTurnController.new())

	var context: GameCommandContext = auto_free(GameCommandContext.new({
		GameConstants.ContextKeys.UNIT_MANAGER: um,
		GameConstants.ContextKeys.LOOT_MANAGER: loot_manager,
		GameConstants.ContextKeys.TURN_CONTROLLER: tc,
		GameConstants.ContextKeys.GRID: auto_free(Node2D.new()),
		GameConstants.ContextKeys.TASK_MANAGER: auto_free(Stubs.FakeTaskManager.new()),
		GameConstants.ContextKeys.MOVE_CONTROLLER: auto_free(Stubs.FakeMoveController.new())
	}))

	var payload: Dictionary = {
		GameConstants.Payload.LOOTER_INDEX: 0,
		GameConstants.Payload.LOOT_COORD: Vector2i(2, 2)
	}

	var command: LootCommand = LootCommand.new()
	var result: CommandResult = command.execute(context, payload)

	assert_bool(result.is_success()).is_true()
	assert_bool(loot_manager.get_loot_at(Vector2i(2, 2)) == null).is_true()
