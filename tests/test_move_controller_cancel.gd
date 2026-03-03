extends GdUnitTestSuite

const MoveController := preload("res://Gameplay/map/move_controller.gd")

class FakeUnit extends Node:
	var tentative := false
	var start_coord := Vector2i(2, 3)

	func has_tentative_move() -> bool:
		return tentative

	func get_start_of_turn_grid_coord() -> Vector2i:
		return start_coord

	func clear_tentative_move() -> void:
		tentative = false

class FakeUnitManager extends Node:
	var entries: Dictionary = {}

	func get_unit(index: int):
		return entries.get(index)

class FakeUnitController extends Node:
	var coord_changes: Array[Dictionary] = []

	func set_coord(index: int, coord: Vector2i) -> void:
		coord_changes.append({"index": index, "coord": coord})

class FakeMapController extends Node:
	func get_terrain_map():
		return null

func test_cancel_tentative_move_for_index_clears_pending_move() -> void:
	var controller := MoveController.new()
	var unit_manager := FakeUnitManager.new()
	var unit := FakeUnit.new()
	unit.tentative = true
	unit_manager.entries[0] = unit
	var unit_controller := FakeUnitController.new()
	controller._unit_manager = unit_manager
	controller._unit_controller = unit_controller
	controller._map_controller = FakeMapController.new()
	var emissions: Array = []
	controller.actions_updated.connect(func(updated_unit, _terrain, _manager, index):
		emissions.append({"unit": updated_unit, "index": index})
	)
	controller.cancel_tentative_move_for_index(0)
	assert_bool(unit.movement.has_tentative_move()).is_false()
	assert_array(unit_controller.coord_changes).contains_exactly([{ "index": 0, "coord": unit.start_coord }])
	assert_array(emissions).contains_exactly([{ "unit": unit, "index": 0 }])

