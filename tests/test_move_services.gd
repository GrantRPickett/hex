extends GdUnitTestSuite


func test_validate_direction_move_accepts_open_hex() -> void:
	var validator := MoveRequestValidator.new()
	var unit := StubMoveUnit.new()
	var manager := StubUnitManager.new()
	var map_controller := StubMapController.new()
	var hex_nav := StubHexNavigator.new()
	var grid := TileMapLayer.new()
	var result := validator.validate_direction_move(manager, hex_nav, map_controller, grid, 0, unit, "EAST", 5, 5, Vector2.ZERO, 0.0)
	assert_bool(result.success).is_true()
	assert_that(result.next).is_equal(Vector2i(3, 2))
	assert_int(result.cost).is_equal(1)

func test_validate_coordinate_move_includes_path_cost() -> void:
	var validator := MoveRequestValidator.new()
	var unit := StubPathUnit.new()
	var manager := StubUnitManager.new()
	var map_controller := StubMapController.new()
	map_controller.terrain.cost_lookup[Vector2i(3, 2)] = 1
	map_controller.terrain.cost_lookup[Vector2i(4, 2)] = 2
	var result := validator.validate_coordinate_move(unit, manager, map_controller, 0, Vector2i(4, 2), 5, 5, Vector2.ZERO, 0.0)
	assert_bool(result.success).is_true()
	assert_int(result.cost).is_equal(3)
	assert_array(result.path).is_equal([Vector2i(3, 2), Vector2i(4, 2)])

func test_execute_move_consumes_points_and_updates_behavior() -> void:
	var service := MoveExecutionService.new()
	var unit := StubExecutionUnit.new()
	var unit_controller := StubUnitController.new()
	var location_controller := StublocationController.new()
	service.execute_move(unit_controller, location_controller, unit, 0, Vector2i(4, 2), 1)
	assert_that(unit_controller.last_coord).is_equal(Vector2i(4, 2))
	assert_int(unit.remaining).is_equal(4)
	assert_that(unit.movement.last_coord).is_equal(Vector2i(4, 2))
	assert_bool(location_controller.checked).is_true()

func test_finalize_tentative_move_commits_unit() -> void:
	var service := MoveExecutionService.new()
	var unit := StubExecutionUnit.new()
	var unit_controller := StubUnitController.new()
	var location_controller := StublocationController.new()
	service.finalize_tentative_move(unit_controller, location_controller, unit, 0, StubTerrainMap.new())
	assert_that(unit_controller.last_coord).is_equal(Vector2i(4, 2))
	assert_int(unit.remaining).is_equal(3)
	assert_bool(location_controller.checked).is_true()

func test_evaluate_post_move_flags_completion_without_actions() -> void:
	var service := MoveExecutionService.new()
	var unit := StubExecutionUnit.new()
	unit.has_move = false
	unit.has_action = false
	var action_manager := StubActionManager.new()
	action_manager.actions = []
	var result := service.evaluate_post_move(unit, null, StubUnitManager.new(), 0, action_manager)
	assert_bool(result.complete_turn).is_true()
	assert_bool(result.emit_actions).is_false()

func test_threat_warning_service_detects_threat() -> void:
	var service := ThreatWarningService.new()
	var unit := StubThreatUnit.new()
	var result := service.evaluate(unit, Vector2i(2, 2), [Vector2i(3, 3)], StubUnitManager.new(), StubTerrainMap.new())
	assert_str(result.message).is_equal(ThreatWarningService.WARNING_MESSAGE)
	assert_bool(service.needs_confirmation()).is_true()

func test_threat_warning_service_acknowledge_and_reset() -> void:
	var service := ThreatWarningService.new()
	var unit := StubThreatUnit.new()
	service.evaluate(unit, Vector2i(2, 2), [Vector2i(3, 3)], StubUnitManager.new(), StubTerrainMap.new())
	var ack := service.acknowledge_warning()
	assert_str(ack).is_equal(ThreatWarningService.ACK_MESSAGE)
	assert_bool(service.needs_confirmation()).is_false()
	service.reset()
	assert_bool(service.needs_confirmation()).is_false()

class StubUnitManager extends RefCounted:
	func get_coord(index: int) -> Vector2i:
		return Vector2i(2, 2)

	func is_occupied(_target: Vector2i, _selected_idx: int = -1) -> bool:
		return false

class StubHexNavigator extends RefCounted:
	func get_direction_map(_current, _grid) -> Dictionary:
		return {"EAST": Vector2i(1, 0)}

class StubTerrainMap extends RefCounted:
	var cost_lookup: Dictionary = {}

	func is_passable(_coord: Vector2i) -> bool:
		return true

	func get_movement_cost(coord: Vector2i) -> int:
		return cost_lookup.get(coord, 1)

class StubMapController extends RefCounted:
	var terrain := StubTerrainMap.new()

	func get_terrain_map():
		return terrain

class StubMoveUnit extends Unit:
	var movement_behavior = null
	var remaining := 5

	func get_remaining_movement_points() -> int:
		return remaining

	func has_tentative_move() -> bool:
		return false

	func get_start_of_turn_grid_coord() -> Vector2i:
		return Vector2i(2, 2)

	func get_path_to_coord(target: Vector2i, _terrain_map, _origin: Vector2i, _budget: int) -> Array[Vector2i]:
		return [target]

class StubPathUnit extends StubMoveUnit:
	func get_path_to_coord(_target: Vector2i, _terrain_map, _origin: Vector2i, _budget: int) -> Array[Vector2i]:
		return [Vector2i(3, 2), Vector2i(4, 2)]

class StubExecutionUnit extends Unit:
	var movement_behavior := StubMovementBehavior.new()
	var remaining := 5
	var has_move := true
	var has_action := true

	func consume_move(amount: int) -> void:
		remaining -= amount

	func has_move_available() -> bool:
		return has_move

	func has_action_available() -> bool:
		return has_action

	func get_tentative_grid_coord() -> Vector2i:
		return Vector2i(4, 2)

	func get_tentative_cost() -> int:
		return 2

	func clear_tentative_move() -> void:
		pass

class StubMovementBehavior extends RefCounted:
	var last_coord: Vector2i = Vector2i.ZERO

	func set_start_of_turn_grid_coord(coord: Vector2i) -> void:
		last_coord = coord

class StubUnitController extends RefCounted:
	var last_coord: Vector2i = Vector2i.ZERO

	func set_coord(_index: int, coord: Vector2i) -> void:
		last_coord = coord

class StublocationController extends RefCounted:
	var checked := false

	func check_location_progress() -> void:
		checked = true

class StubActionManager extends RefCounted:
	var actions: Array = []

	func get_available_actions(_unit, _terrain_map, _unit_manager) -> Array:
		return actions

class StubThreatBehavior extends RefCounted:
	func get_threatened_hexes(_unit_manager, _terrain_map) -> Array:
		return [Vector2i(2, 2)]

class StubThreatUnit extends StubMoveUnit:
	func _init() -> void:
		movement_behavior = StubThreatBehavior.new()
