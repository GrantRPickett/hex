extends GdUnitTestSuite

const ActionAvailabilityService = preload("res://Gameplay/action_availability_service.gd")

class GoalProbe extends GoalManager:
	var target_coord: Vector2i = Vector2i(-999, -999)
	var stored_goal: Goal = null
	func set_goal(coord: Vector2i, goal: Goal) -> void:
		target_coord = coord
		stored_goal = goal
	func get_goal_at_cell(coord: Vector2i):
		if coord == target_coord:
			return stored_goal
		return null

class AlwaysWorkGoal extends Goal:
	func can_be_worked_on_by(unit: Unit, interaction_range: float = 0.5) -> bool:
		return true

func test_is_unit_not_stuck_when_goal_at_tentative_position() -> void:
	var service: ActionAvailabilityService = ActionAvailabilityService.new()
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, Vector2i(0, 0), true)
	var goal_manager: GoalProbe = auto_free(GoalProbe.new())
	var goal: Goal = AlwaysWorkGoal.new()
	goal_manager.set_goal(Vector2i(2, 0), goal)
	unit.set_goal_manager(goal_manager)
	unit.set_tentative_move(Vector2i(2, 0), [], 1)
	var result: bool = service.is_unit_stuck(unit, null, manager)
	assert_bool(result).is_false()
