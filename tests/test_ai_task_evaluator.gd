extends GdUnitTestSuite

const TaskEvaluatorClass := preload("res://Gameplay/turn/ai/task_evaluator.gd")
const AIContextClass := preload("res://Gameplay/turn/ai/ai_context.gd")
const AIActionClass := preload("res://Gameplay/turn/ai/ai_action.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const TaskClass := preload("res://Gameplay/narrative/task/task.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const StageClass := preload("res://Gameplay/narrative/task/stage.gd")
const ObjectiveClass := preload("res://Gameplay/narrative/task/objective.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")
const LocationClass := preload("res://Gameplay/targets/location.gd")

class FakeTask extends TaskClass:
	var _can_be_worked := true
	func can_be_worked_on_by(_unit: UnitClass, _coord: Vector2i = GameConstants.INVALID_COORD) -> bool:
		return _can_be_worked

func test_evaluate_returns_work_on_task_if_at_location() -> void:
	var evaluator: TaskEvaluatorClass = auto_free(TaskEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.set_grid_location(Vector2i(1, 1))

	var context: AIContextClass = AIContextClass.new()
	var task_manager := Stubs.FakeTaskManager.new()
	context.task_manager = task_manager
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	var loc = auto_free(LocationClass.new())
	var task := FakeTask.new()
	task.event_type = GameConstants.Interactions.EXPLORE
	task_manager.set_location(Vector2i(1, 1), loc)
	task_manager.set_task_for_target(loc, task)

	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].type).is_equal(TaskEvaluatorClass.ACTION_EXPLORE)
	assert_object(actions[0].target).is_same(task)
	# Base 85.0 * 0.85 weight = 72.25
	assert_float(actions[0].score).is_equal(72.25)

func test_evaluate_returns_move_to_task_for_distant_task() -> void:
	var evaluator: TaskEvaluatorClass = auto_free(TaskEvaluatorClass.new())
	var unit: Stubs.FakeUnit = Stubs.FakeUnit.new()
	unit.set_grid_location(Vector2i(1, 1))
	unit._paths[Vector2i(2, 2)] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]

	var context: AIContextClass = AIContextClass.new()
	var task_manager := Stubs.FakeTaskManager.new()
	context.task_manager = task_manager
	context.terrain_map = Stubs.FakeTerrainMap.new() as TerrainMapClass
	context.unit_manager = Stubs.FakeUnitManager.new()

	var task := FakeTask.new()
	task.status = TaskClass.Status.ACTIVE
	task.target_coord = Vector2i(2, 2)

	var stage: StageClass = auto_free(StageClass.new())
	stage.active_tasks = [task]
	var obj: ObjectiveClass = auto_free(ObjectiveClass.new())
	obj.current_stage = stage
	task_manager.set_active_objective(obj)

	var actions = evaluator.evaluate(unit, context)
	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].type).is_equal(TaskEvaluatorClass.ACTION_MOVE_TO_TASK)
	assert_vector(actions[0].target).is_equal(Vector2i(2, 2))
