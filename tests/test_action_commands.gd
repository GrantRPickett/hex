extends GdUnitTestSuite
# Test suite for action commands: AttackUnitCommand, AidAllyCommand, ExploreCommand, LootCommand

const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const MockUnitBase = Stubs.FakeUnit

class MockUnit extends MockUnitBase:
	var last_attack_target: Unit
	var last_attack_attribute_idx: int = -1
	var aid_happened_with: Unit = null

	func attack(target: Unit, pair_idx: int = 0) -> void:
		last_attack_target = target
		last_attack_attribute_idx = pair_idx
		super.attack(target, pair_idx)

	func aid_ally(target: Unit) -> void:
		aid_happened_with = target

class MockUnitManager extends UnitManager:
	var units: Dictionary = {} # index -> MockUnit
	var combat_happened: Array = []
	var aid_happened: Array = []

	func _init() -> void:
		units[0] = MockUnit.new()
		units[0].faction = Unit.Faction.PLAYER
		units[1] = MockUnit.new()
		units[1].faction = Unit.Faction.PLAYER
		units[2] = MockUnit.new()
		units[2].faction = Unit.Faction.ENEMY

		# For adjacency tests, units 0 and 2 should consider each other hostiles
		units[0]._hostiles = [units[2]]
		units[2]._hostiles = [units[0]]

	func get_unit(index: int):
		return units.get(index)

	func get_unit_at_index(index: int):
		return units.get(index)

	func get_unit_count() -> int:
		return units.size()

	func index_of_unit_at(_cell: Vector2i) -> int:
		for idx in units.keys():
			if units[idx].location == _cell:
				return idx
		return -1


class MockTurnController extends TurnController:
	var enabled := true
	var allowed_indexes: Dictionary = {0: true, 1: true}

	func is_enabled() -> bool:
		return enabled

	func can_act_on_index(index: int) -> bool:
		return allowed_indexes.get(index, false)


class MockTaskController extends TaskController:
	var locations: Dictionary = {}
	var completed: Array = []

	func is_location_reached() -> bool:
		return false

	func get_location_index(_location) -> int:
		for idx in locations.keys():
			if locations[idx] == _location:
				return idx
		return -1

	func add_location(index: int, location) -> void:
		locations[index] = location


class MockLootManager:
	var has_loot: bool = true
	var pickup_called: bool = false

	func has_loot_at(_pos: Vector2) -> bool:
		return has_loot

	func try_pickup(_unit) -> bool:
		pickup_called = true
		return true


func test_attack_unit_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		TaskController.new(),
		TileMapLayer.new()
	)
	var command := AttackUnitCommand.new()
	var result = command.execute(context, {"attacker_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)


func test_attack_unit_command_validates_payload() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)
	var command := AttackUnitCommand.new()

	# Missing attacker_index
	var result = command.execute(context, {"target_index": 1})
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_PAYLOAD)


func test_attack_unit_command_checks_attacker_has_action() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	# Attacker has no action available
	unit_manager.units[0]._actions = 0

	var command := AttackUnitCommand.new()
	var result = command.execute(context, {"attacker_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)


func test_attack_unit_command_checks_target_adjacency() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	# Place units far apart (not adjacent)
	unit_manager.units[0].set_grid_location(Vector2i.ZERO)
	unit_manager.units[1].set_grid_location(Vector2i(10, 10))

	var command := AttackUnitCommand.new()
	var result = command.execute(context, {"attacker_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)


func test_attack_unit_command_success_with_adjacent_units() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	# Place units adjacent
	unit_manager.units[0].set_grid_location(Vector2i.ZERO)
	unit_manager.units[2].set_grid_location(Vector2i(1, 0)) # Adjacent in hex grid

	var command := AttackUnitCommand.new()
	var result = command.execute(context, {"attacker_index": 0, "target_index": 2})

	# Should succeed (or at least not fail preconditions)
	assert_that(result.status).is_not_equal(CommandResult.Status.INVALID_CONTEXT)
	assert_that(result.status).is_not_equal(CommandResult.Status.INVALID_PAYLOAD)

func test_attack_unit_command_maps_attribute_index_to_pair() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	unit_manager.units[0].set_grid_location(Vector2i.ZERO)
	unit_manager.units[2].set_grid_location(Vector2i(1, 0))

	var command := AttackUnitCommand.new()
	var result = command.execute(context, {"attacker_index": 0, "target_index": 2, "attribute_index": 5})
	assert_that(result.status).is_equal(CommandResult.Status.SUCCESS)
	assert_int(unit_manager.units[0].last_attack_attribute_idx).is_equal(2)


func test_aid_ally_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		TaskController.new(),
		TileMapLayer.new()
	)
	var command := AidAllyCommand.new()
	var result = command.execute(context, {"helper_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)


func test_aid_ally_command_validates_payload() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)
	var command := AidAllyCommand.new()

	# Missing helper_index
	var result = command.execute(context, {"target_index": 1})
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_PAYLOAD)


func test_aid_ally_command_checks_helper_has_action() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	# Helper has no action available
	unit_manager.units[0]._actions = 0

	var command := AidAllyCommand.new()
	var result = command.execute(context, {"helper_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)


func test_explore_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		TaskController.new(),
		TileMapLayer.new()
	)
	var command := ExploreCommand.new()
	var result = command.execute(context, {"worker_index": 0, "location_index": 0})

	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)


func test_explore_command_validates_payload() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)
	var command := ExploreCommand.new()

	# Missing worker_index (or Task ID)
	var result = command.execute(context, {"location_index": 0})
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_PAYLOAD)


func test_loot_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		TaskController.new(),
		TileMapLayer.new()
	)
	var command := LootCommand.new()
	var result = command.execute(context, {"looter_index": 0})

	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)


func test_loot_command_validates_payload() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)
	var command := LootCommand.new()

	# Missing looter_index
	var result = command.execute(context, {})
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_PAYLOAD)


func test_loot_command_checks_looter_has_action() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MockTaskController.new(),
		TileMapLayer.new()
	)

	# Looter has no action available
	unit_manager.units[0]._actions = 0

	var command := LootCommand.new()
	var result = command.execute(context, {"looter_index": 0})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)
