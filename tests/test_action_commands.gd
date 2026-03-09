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
	var command: AttackUnitCommand = AttackUnitCommand.new(attacker, target, 1)

	var result: CommandResult = command.execute()
	assert_bool(result.is_success()).is_true()
	assert_object(attacker.last_attack_target).is_equal(target)
	assert_int(attacker.last_attack_attribute_idx).is_equal(1)

func test_aid_ally_command_execution() -> void:
	var aider: MockUnit = auto_free(MockUnit.new())
	var ally: MockUnit = auto_free(MockUnit.new())
	var command: AidAllyCommand = AidAllyCommand.new(aider, ally)

	var result: CommandResult = command.execute()
	assert_bool(result.is_success()).is_true()
	assert_object(aider.aid_happened_with).is_equal(ally)

func test_explore_command_execution() -> void:
	var unit: MockUnit = auto_free(MockUnit.new())
	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	unit.set_task_manager(task_manager)

	var command: ExploreCommand = ExploreCommand.new(unit, Vector2i(1, 1))
	var result: CommandResult = command.execute()

	assert_bool(result.is_success()).is_true()
	assert_int(task_manager.last_coord.x).is_equal(1)
	assert_int(task_manager.last_coord.y).is_equal(1)

func test_loot_command_execution() -> void:
	var unit: MockUnit = auto_free(MockUnit.new())
	var loot_manager: LootManager = auto_free(LootManager.new())
	var loot: Loot = Loot.new()
	loot_manager.add_loot(loot, Vector2i(2, 2))
	unit.set_loot_manager(loot_manager)

	var command: LootCommand = LootCommand.new(unit, Vector2i(2, 2))
	var result: CommandResult = command.execute()

	assert_bool(result.is_success()).is_true()
	assert_bool(loot_manager.get_loot_at(Vector2i(2, 2)) == null).is_true()
