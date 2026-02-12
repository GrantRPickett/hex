extends GdUnitTestSuite

const ActionAvailabilityService = preload("res://Gameplay/action_availability_service.gd")

class LocationProbe extends LocationManager:
	var target_coord: Vector2i = Vector2i(-999, -999)
	var stored_target_task: TargetTask = null
	func set_target_task(coord: Vector2i, target_task: TargetTask) -> void:
		target_coord = coord
		stored_target_task = target_task
	func get_location_at_cell(coord: Vector2i):
		if coord == target_coord:
			return stored_target_task
		return null

class AlwaysWorkTargetTask extends TargetTask:
	func can_be_worked_on_by(unit: Unit, interaction_range: float = 0.5) -> bool:
		return true

func test_is_unit_not_stuck_when_location_at_tentative_position() -> void:
	var service: ActionAvailabilityService = ActionAvailabilityService.new()
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var location_manager: LocationProbe = auto_free(LocationProbe.new())
	var target_task: TargetTask = AlwaysWorkTargetTask.new()
	location_manager.set_target_task(Vector2i(2, 0), target_task)
	unit.set_location_manager(location_manager)
	unit.set_tentative_move(Vector2i(2, 0), [], 1)
	var result: bool = service.is_unit_stuck(unit, null, manager)
	assert_bool(result).is_false()
