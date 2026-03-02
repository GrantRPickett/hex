extends GdUnitTestSuite

const TaskEvaluator := preload("res://Gameplay/turn/ai/task_evaluator.gd")
const AIContext := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIAction := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const Task := preload("res://Gameplay/narrative/task/task.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")
const Stage := preload("res://Gameplay/narrative/task/stage.gd")
const Objective := preload("res://Gameplay/narrative/task/objective.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")

class FakeTaskManager extends Stubs.FakeTaskManager:
	var _active_obj: Objective
	var _mock_locations: Dictionary = {}
	var _tasks: Dictionary = {}

	func set_active_objective(obj: Objective) -> void:
		_active_obj = obj

	func get_active_objective() -> Objective:
		return _active_obj

	func get_location_at(coord: Vector2i):
		return _mock_locations.get(coord)

	func get_task_for_target(loc):
		return _tasks.get(loc)

class FakeTask extends Task:
	var _can_be_worked := true
	func can_be_worked_on_by(_unit: Unit) -> bool:
		return _can_be_worked

func test_evaluate_returns_work_on_task_if_at_location() -> void:
	var evaluator: TaskEvaluator = auto_free(TaskEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit._grid_location = Vector2i(1, 1)

	var context: AIContext = AIContext.new()
	var task_manager := FakeTaskManager.new()
	context.task_manager = task_manager
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	var loc = Node2D.new()
	var task := FakeTask.new()
	task_manager._mock_locations[Vector2i(1, 1)] = loc
	task_manager._tasks[loc] = task

	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(TaskEvaluator.ACTION_WORK_ON_TASK)
	assert_that(actions[0].target).is_same(task)

func test_evaluate_returns_move_to_task_for_distant_task() -> void:
	var evaluator: TaskEvaluator = auto_free(TaskEvaluator.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit._grid_location = Vector2i(1, 1)
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var context: AIContext = AIContext.new()
	var task_manager := FakeTaskManager.new()
	context.task_manager = task_manager
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	var task := FakeTask.new()
	task.status = Task.Status.ACTIVE
	task.target_coord = Vector2i(2, 2)

	var stage: Stage = Stage.new()
	stage.active_tasks = [task]
	var obj: Objective = Objective.new()
	obj.current_stage = stage
	task_manager.set_active_objective(obj)

	var actions: Array[AIAction] = evaluator.evaluate(unit, context)
	assert_that(actions.size()).is_equal(1)
	assert_that(actions[0].type).is_equal(TaskEvaluator.ACTION_MOVE_TO_TASK)
	assert_that(actions[0].target).is_equal(Vector2i(2, 2))
