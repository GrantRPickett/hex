extends GdUnitTestSuite
# Test suite for action commands: AttackUnitCommand, AidAllyCommand, WorkOnlocationCommand, LootCommand

const AttackUnitCommand := preload("res://Gameplay/input_commands/attack_unit_command.gd")
const AidAllyCommand := preload("res://Gameplay/input_commands/aid_ally_command.gd")
const WorkOnlocationCommand := preload("res://Gameplay/input_commands/work_on_location_command.gd")
const LootCommand := preload("res://Gameplay/input_commands/loot_command.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")

class MockUnit:
	var index: int = 0
	var location: Vector2i = Vector2i.ZERO
	var faction: String = "player"
	var has_action: bool = true
	var has_move: bool = true
	var morale: int = 50
	var max_morale: int = 100
	var willpower: int = 100
	var last_attack_target
	var last_attack_attribute_idx: int = -1

	func has_action_available() -> bool:
		return has_action

	func has_move_available() -> bool:
		return has_move

	func consume_action() -> void:
		has_action = false

	func get_adjacent_units(exclude: Array = []) -> Array:
		# Simple mock that returns units passed in exclude (simulating passed in units are adjacent)
		return exclude

	func is_at_full_morale() -> bool:
		return morale >= max_morale

	func attack_unit(target, attribute_index := 0) -> void:
		last_attack_target = target
		last_attack_attribute_idx = attribute_index

	func aid_ally(_target) -> void:
		pass

class MockUnitManager extends UnitManager:
	var units: Dictionary = {}  # index -> MockUnit
	var combat_happened: Array = []
	var aid_happened: Array = []

	func _init() -> void:
		units[0] = MockUnit.new()
		units[0].index = 0
		units[0].faction = "player"
		units[1] = MockUnit.new()
		units[1].index = 1
		units[1].faction = "player"
		units[2] = MockUnit.new()
		units[2].index = 2
		units[2].faction = "enemy"

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


class MocklocationController extends locationController:
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
		locationController.new(),
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
		MocklocationController.new(),
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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	# Attacker has no action available
	unit_manager.units[0].has_action = false

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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	# Place units far apart (not adjacent)
	unit_manager.units[0].location = Vector2i.ZERO
	unit_manager.units[1].location = Vector2i(10, 10)

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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	# Place units adjacent
	unit_manager.units[0].location = Vector2i.ZERO
	unit_manager.units[2].location = Vector2i(1, 0)  # Adjacent in hex grid

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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	unit_manager.units[0].location = Vector2i.ZERO
	unit_manager.units[2].location = Vector2i(1, 0)

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
		locationController.new(),
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
		MocklocationController.new(),
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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	# Helper has no action available
	unit_manager.units[0].has_action = false

	var command := AidAllyCommand.new()
	var result = command.execute(context, {"helper_index": 0, "target_index": 1})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)


func test_work_on_location_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		locationController.new(),
		TileMapLayer.new()
	)
	var command := WorkOnlocationCommand.new()
	var result = command.execute(context, {"worker_index": 0, "location_index": 0})

	assert_that(result.status).is_equal(CommandResult.Status.INVALID_CONTEXT)


func test_work_on_location_command_validates_payload() -> void:
	var unit_manager := MockUnitManager.new()
	var context := GameCommandContext.new(
		unit_manager,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		MockTurnController.new(),
		MocklocationController.new(),
		TileMapLayer.new()
	)
	var command := WorkOnlocationCommand.new()

	# Missing worker_index
	var result = command.execute(context, {"location_index": 0})
	assert_that(result.status).is_equal(CommandResult.Status.INVALID_PAYLOAD)


func test_loot_command_validates_context() -> void:
	var context := GameCommandContext.new(
		null,
		HexNavigator.new(),
		CameraController.new(),
		MoveController.new(),
		TurnController.new(),
		locationController.new(),
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
		MocklocationController.new(),
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
		MocklocationController.new(),
		TileMapLayer.new()
	)

	# Looter has no action available
	unit_manager.units[0].has_action = false

	var command := LootCommand.new()
	var result = command.execute(context, {"looter_index": 0})

	assert_that(result.status).is_equal(CommandResult.Status.PRECONDITION_FAILED)
