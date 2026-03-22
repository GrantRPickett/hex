extends GdUnitTestSuite

const HUDController = preload("res://GUI/HUD/hud_controller.gd")
const TurnController = preload("res://Gameplay/turn/turn_controller.gd")
const TurnSystem = preload("res://Gameplay/turn/turn_system.gd")
const UnitClass = preload("res://Gameplay/targets/unit.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

class TestUnitManager extends Stubs.FakeUnitManager:
	var player_indices: Array[int] = []
	func is_player_controlled(index: int) -> bool:
		return index in player_indices

func test_calculate_faction_turn_counts() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)

	var turn_controller = auto_free(TurnController.new())
	var unit_manager = auto_free(TestUnitManager.new())

	controller._turn_controller = turn_controller
	controller._unit_manager = unit_manager
	turn_controller._unit_manager = unit_manager

	var p_unit1 = auto_free(Stubs.FakeUnit.new())
	p_unit1.faction = UnitClass.Faction.PLAYER
	var p_unit2 = auto_free(Stubs.FakeUnit.new())
	p_unit2.faction = UnitClass.Faction.PLAYER
	var e_unit1 = auto_free(Stubs.FakeUnit.new())
	e_unit1.faction = UnitClass.Faction.ENEMY
	var n_unit1 = auto_free(Stubs.FakeUnit.new())
	n_unit1.faction = UnitClass.Faction.NEUTRAL

	unit_manager.add_unit(p_unit1, Vector2i(0, 0)) # index 0
	unit_manager.add_unit(p_unit2, Vector2i(0, 1)) # index 1
	unit_manager.add_unit(e_unit1, Vector2i(1, 0)) # index 2
	unit_manager.add_unit(n_unit1, Vector2i(1, 1)) # index 3
	unit_manager.player_indices = [0, 1]

	turn_controller._turn_queue = [0, 1, 2, 3]

	var counts = controller._calculate_faction_turn_counts()

	assert_int(counts.get(GameConstants.Side.PLAYER)).is_equal(2)
	assert_int(counts.get(GameConstants.Side.ENEMY)).is_equal(1)
	assert_int(counts.get(GameConstants.Side.NEUTRAL)).is_equal(1)
