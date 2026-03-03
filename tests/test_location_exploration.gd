extends GdUnitTestSuite

const TaskActionProvider := preload("res://Gameplay/narrative/task/task_action_provider.gd")
const Task := preload("res://Gameplay/narrative/task/task.gd")
const Location := preload("res://Gameplay/targets/location.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")
const TestStubs := preload("res://tests/fixtures/test_stubs.gd")
const Objective := preload("res://Gameplay/narrative/task/objective.gd")
const Stage := preload("res://Gameplay/narrative/task/stage.gd")

func test_explore_action_added() -> void:
	var unit := TestStubs.FakeUnit.new()
	unit.unit_name = "Explorer"
	unit.set_attribute_values({"grit": 10})

	var loc := Location.new()
	loc.loc_name = "Mysterious Cave"
	loc.coord = Vector2i(1, 1)

	var task := Task.new()
	task.id = &"explore_cave"
	task.title = "Explore Cave"
	task.event_type = "explore"
	task.target_coord = Vector2i(1, 1)
	task.effort_required = 5
	task.initialize()

	var stage := Stage.new()
	stage.active_tasks = [task]

	var objective := Objective.new()
	objective.current_stage = stage
	objective.is_active = true

	var task_manager := TestStubs.FakeTaskManager.new()
	task_manager.set_location(Vector2i(1, 1), loc)
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider := TaskActionProvider.new()
	var actions: Array[Dictionary] = []
	provider.append_task_action(actions, unit, Vector2i(1, 1))

	assert_int(actions.size()).is_equal(6)
	assert_str(actions[0].type).is_equal("work_on_task")
	assert_bool("Explore Cave" in actions[0].label).is_true()
	assert_bool("Grit" in actions[0].label).is_true()
	assert_that(actions[0].interact_target_coord).is_equal(Vector2i(1, 1))

	unit.free()
	loc.free()

func test_interact_action_still_works() -> void:
	var unit := TestStubs.FakeUnit.new()
	unit.unit_name = "Worker"
	unit.set_attribute_values({"grit": 10})

	var loc := Location.new()
	loc.loc_name = "Old Mill"
	loc.coord = Vector2i(2, 2)

	var task := Task.new()
	task.id = &"fix_mill"
	task.title = "Fix Mill"
	task.event_type = "interact"
	task.target_coord = Vector2i(2, 2)
	task.effort_required = 5
	task.initialize()

	var stage := Stage.new()
	stage.active_tasks = [task]

	var objective := Objective.new()
	objective.current_stage = stage
	objective.is_active = true

	var task_manager := TestStubs.FakeTaskManager.new()
	task_manager.set_location(Vector2i(2, 2), loc)
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider := TaskActionProvider.new()
	var actions: Array[Dictionary] = []
	provider.append_task_action(actions, unit, Vector2i(2, 2))

	assert_int(actions.size()).is_equal(6)
	assert_str(actions[0].type).is_equal("work_on_task")
	assert_bool("Fix Mill" in actions[0].label).is_true()

	unit.free()
	loc.free()
