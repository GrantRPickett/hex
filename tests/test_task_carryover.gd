extends GdUnitTestSuite

const ObjectiveScript := preload("res://Gameplay/narrative/task/objective.gd")
const StageScript := preload("res://Gameplay/narrative/task/stage.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")

func _make_level() -> Level:
	var l: Level = Level.new()
	auto_free(l)
	return l

func _make_task(id: StringName, carryover: bool = false, effort: int = 10) -> Task:
	var t: Task = TaskScript.new()
	auto_free(t)
	t.id = id
	t.carryover_to_next_stage = carryover
	t.effort_required = effort
	t.event_type = "test_event"
	return t

func _make_stage(id: StringName, tasks: Array[Task] = []) -> Stage:
	var s: Stage = StageScript.new()
	auto_free(s)
	s.id = id
	s.tasks = tasks
	return s

func _make_objective(obj_id: String = "obj_test") -> Objective:
	var o: Objective = ObjectiveScript.new(obj_id, "Test Objective", "A test")
	auto_free(o)
	return o

func test_task_carryover_persists_to_next_stage() -> void:
	var obj := _make_objective()
	
	var task_a := _make_task(&"task_a", false) # Mandatory, triggers transition
	var task_b := _make_task(&"task_b", true)  # Carryover
	
	var stage_2 := _make_stage(&"stage_2", [])
	var stage_1 := _make_stage(&"stage_1", [task_a, task_b])
	stage_1.default_next_stage = stage_2
	
	obj.starting_stage = stage_1
	obj.start_objective(_make_level())
	
	assert_int(obj.current_stage.active_tasks.size()).is_equal(2)
	var active_task_b = obj.current_stage.active_tasks[1]
	assert_str(active_task_b.id).is_equal("task_b")
	
	# Add some progress to task_b
	obj.handle_event("test_event", {"unit": null, "progress": 5})
	assert_int(active_task_b.current_effort).is_equal(5)
	
	# Complete task_a to trigger transition
	obj.handle_event("test_event", {"id": "task_a", "unit": null, "progress": 10})
	
	# Verify we transitioned to stage_2
	assert_str(obj.current_stage.id).is_equal("stage_2")
	
	# Verify task_b carried over
	assert_int(obj.current_stage.active_tasks.size()).is_equal(1)
	var carried_task = obj.current_stage.active_tasks[0]
	assert_str(carried_task.id).is_equal("task_b")
	assert_int(carried_task.current_effort).is_equal(5)
	assert_int(carried_task.status).is_equal(Task.Status.ACTIVE)

func test_task_carryover_merges_with_existing_task_id() -> void:
	var obj := _make_objective()
	
	var task_a := _make_task(&"task_a", false)
	var task_b_v1 := _make_task(&"task_b", true, 20)
	
	var task_b_v2 := _make_task(&"task_b", false, 20) # Defined in stage 2 as well
	
	var stage_2 := _make_stage(&"stage_2", [task_b_v2])
	var stage_1 := _make_stage(&"stage_1", [task_a, task_b_v1])
	stage_1.default_next_stage = stage_2
	
	obj.starting_stage = stage_1
	obj.start_objective(_make_level())
	
	# Add progress to task_b in stage 1
	obj.handle_event("test_event", {"id": "task_b", "unit": null, "progress": 8})
	
	# Complete task_a to transition
	obj.handle_event("test_event", {"id": "task_a", "unit": null, "progress": 10})
	
	# Verify transition
	assert_str(obj.current_stage.id).is_equal("stage_2")
	
	# Verify task_b is the SAME instance or at least has the SAME progress
	# Based on my implementation, it should be the same instance
	assert_int(obj.current_stage.active_tasks.size()).is_equal(1)
	var active_task = obj.current_stage.active_tasks[0]
	assert_str(active_task.id).is_equal("task_b")
	assert_int(active_task.current_effort).is_equal(8)
	
	# Verify it still works in stage 2
	obj.handle_event("test_event", {"id": "task_b", "unit": null, "progress": 2})
	assert_int(active_task.current_effort).is_equal(10)

func test_transplant_task_manually_marks_for_carryover() -> void:
	var obj := _make_objective()
	
	var task_a := _make_task(&"task_a", false)
	var task_b := _make_task(&"task_b", false) # NOT marked for carryover in resource
	
	var stage_2 := _make_stage(&"stage_2", [])
	var stage_1 := _make_stage(&"stage_1", [task_a, task_b])
	stage_1.default_next_stage = stage_2
	
	obj.starting_stage = stage_1
	obj.start_objective(_make_level())
	
	# Manually transplant task_b
	obj.transplant_task(&"task_b")
	
	# Complete task_a to transition
	obj.handle_event("test_event", {"id": "task_a", "unit": null, "progress": 10})
	
	# Verify transition
	assert_str(obj.current_stage.id).is_equal("stage_2")
	
	# Verify task_b carried over despite not being marked in resource
	assert_int(obj.current_stage.active_tasks.size()).is_equal(1)
	assert_str(obj.current_stage.active_tasks[0].id).is_equal("task_b")

func test_non_carryover_tasks_are_cancelled() -> void:
	var obj := _make_objective()
	
	var task_a := _make_task(&"task_a", false)
	var task_b := _make_task(&"task_b", false) # No carryover
	
	var stage_2 := _make_stage(&"stage_2", [])
	var stage_1 := _make_stage(&"stage_1", [task_a, task_b])
	stage_1.default_next_stage = stage_2
	
	obj.starting_stage = stage_1
	obj.start_objective(_make_level())
	
	var active_task_b = obj.current_stage.active_tasks[1]
	
	# Complete task_a to transition
	obj.handle_event("test_event", {"id": "task_a", "unit": null, "progress": 10})
	
	# Verify transition
	assert_str(obj.current_stage.id).is_equal("stage_2")
	
	# Verify task_b is NOT in stage 2
	assert_int(obj.current_stage.active_tasks.size()).is_equal(0)
	
	# Verify task_b was cancelled
	assert_int(active_task_b.status).is_equal(Task.Status.CANCELLED)
