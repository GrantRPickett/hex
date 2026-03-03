extends GdUnitTestSuite

class MockController:
	func get_round() -> int:
		return 2

	func get_current_unit_index() -> int:
		return 1

	func get_current_side() -> int:
		return TurnSystem.Side.PLAYER

var _mock_controller: RefCounted
var _turn_system: TurnSystem

func before() -> void:
	_mock_controller = auto_free(MockController.new())
	_turn_system = auto_free(TurnSystem.new())

func test_get_current_round_with_controller() -> void:
	var result = _turn_system.get_current_round()

	assert_int(result).is_equal(2)

func test_get_current_unit_index_with_controller() -> void:
	var result = _turn_system.get_current_unit_index()

	assert_int(result).is_equal(1)

func test_get_current_side_with_controller() -> void:
	var result = _turn_system.get_current_side()

	assert_int(result).is_equal(TurnSystem.Side.PLAYER)

func test_get_current_round_without_controller() -> void:
	var system = auto_free(TurnSystem.new())

	var result = system.get_current_round()

	assert_int(result).is_equal(1)

func test_get_current_unit_index_without_controller() -> void:
	var system = auto_free(TurnSystem.new())

	var result = system.get_current_unit_index()

	assert_int(result).is_equal(-1)

func test_get_current_side_without_controller() -> void:
	var system = auto_free(TurnSystem.new())

	var result = system.get_current_side()

	assert_int(result).is_equal(TurnSystem.Side.NEUTRAL)
