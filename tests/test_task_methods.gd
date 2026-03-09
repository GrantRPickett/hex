extends GdUnitTestSuite

const TaskClass := preload("res://Gameplay/narrative/task/task.gd")
const TaskManagerClass := preload("res://Gameplay/narrative/task/task_manager.gd")
const ObjectiveClass := preload("res://Gameplay/narrative/task/objective.gd")

func test_task_force_complete() -> void:
	var task = auto_free(TaskClass.new())
	task.effort_required = 10
	task.initialize()
	assert_int(task.current_effort).is_equal(0)
	task.force_complete()
	assert_int(task.current_effort).is_equal(10)
	assert_int(task.status as int).is_equal(TaskClass.Status.COMPLETED)

func test_task_get_progress_ratio() -> void:
	var task = auto_free(TaskClass.new())
	task.effort_required = 10
	task.current_effort = 5
	assert_float(task.get_progress_ratio()).is_equal(0.5)

func test_task_manager_prepare_objective() -> void:
	var mgr = auto_free(TaskManagerClass.new())
	var obj = auto_free(ObjectiveClass.new())
	obj.id = "obj1"

	assert_object(mgr.get_active_objective()).is_null()
	mgr.prepare_objective(obj)
	assert_object(mgr.get_active_objective()).is_same(obj)

func test_task_manager_debug_complete() -> void:
	var mgr = auto_free(TaskManagerClass.new())
	var obj = auto_free(ObjectiveClass.new())
	var stage = auto_free(preload("res://Gameplay/narrative/task/stage.gd").new())
	var task = auto_free(TaskClass.new())
	task.id = "task1"
	task.effort_required = 10
	task.initialize()
	stage.active_tasks = [task]
	obj.current_stage = stage
	mgr.prepare_objective(obj)
	mgr._start_objective(obj)

	assert_int(task.status as int).is_equal(TaskClass.Status.ACTIVE)
	mgr.debug_complete_task("task1")
	assert_int(task.status as int).is_equal(TaskClass.Status.COMPLETED)
