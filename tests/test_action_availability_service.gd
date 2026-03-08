extends GdUnitTestSuite

class LocationProbe extends TaskManager:
	var target_coord: Vector2i = Vector2i(-999, -999)
	var stored_target_task: Task = null
	var mock_location: Location = null

	func set_target_task(coord: Vector2i, target_task: Task) -> void:
		target_coord = coord
		stored_target_task = target_task
		mock_location = Location.new()
		mock_location.coord = coord

	func get_location_at(coord: Vector2i) -> Location:
		if coord == target_coord:
			return mock_location
		return null

	func get_task_for_target(target: Target) -> Task:
		if target == mock_location:
			return stored_target_task
		return null

class AlwaysWorkTask extends Task:
	func can_be_worked_on_by(_unit: Unit, from_coord: Vector2i = Vector2i(-1, -1)) -> bool:
		return true

func test_is_unit_not_stuck_when_location_at_tentative_position() -> void:
	var service: ActionAvailabilityService = ActionAvailabilityService.new()
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var task_manager: LocationProbe = auto_free(LocationProbe.new())
	var target_task: Task = AlwaysWorkTask.new()
	task_manager.set_target_task(Vector2i(2, 0), target_task)
	unit.set_task_manager(task_manager)
	unit.movement.set_tentative_move(Vector2i(2, 0), [], 1)
	var result: bool = service.is_unit_stuck(unit, null, manager)
	assert_bool(result).is_false()
