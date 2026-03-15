extends GdUnitTestSuite

const LocationActionProvider := preload("res://Gameplay/targets/location_action_provider.gd")
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

	var provider := LocationActionProvider.new()
	var actions: Array[UnitAction] = []
	# Passing empty reachable arrays for this test
	provider.append_location_action(actions, unit, Vector2i(1, 1), [], {})

	assert_int(actions.size()).is_equal(1)
	assert_int(actions[0].type).is_equal(UnitAction.Type.EXPLORE)
	# Summary label params
	assert_int(actions[0].label_params.get("near")).is_equal(1)
	assert_int(actions[0].label_params.get("reachable")).is_equal(0)
	assert_that(actions[0].target).is_equal(loc)

	unit.free()
	loc.free()

func test_reachable_explore_action_added() -> void:
	var unit := TestStubs.FakeUnit.new()
	unit.set_attribute_values({"grit": 10})

	var loc := Location.new()
	loc.loc_name = "Distant Ruin"
	loc.coord = Vector2i(5, 5)

	var task := Task.new()
	task.id = &"explore_ruin"
	task.title = "Explore Ruin"
	task.event_type = "explore"
	task.target_coord = Vector2i(5, 5)
	task.effort_required = 5
	task.initialize()

	var stage := Stage.new()
	stage.active_tasks = [task]

	var objective := Objective.new()
	objective.current_stage = stage
	objective.is_active = true

	var task_manager := TestStubs.FakeTaskManager.new()
	task_manager.set_location(Vector2i(5, 5), loc)
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider := LocationActionProvider.new()
	var actions: Array[UnitAction] = []
	# Origin is 1,1; Ruin is reachable at 5,5
	provider.append_location_action(actions, unit, Vector2i(1, 1), [Vector2i(5, 5)], {Vector2i(5, 5): 3})

	assert_int(actions.size()).is_equal(1)
	assert_int(actions[0].type).is_equal(UnitAction.Type.EXPLORE)
	assert_int(actions[0].label_params.get("near")).is_equal(0)
	assert_int(actions[0].label_params.get("reachable")).is_equal(1)
	assert_int(actions[0].reachable_targets.size()).is_equal(1)
	assert_that(actions[0].reachable_targets[0]).is_equal(loc)

	unit.free()
	loc.free()

func test_abstract_task_no_action() -> void:
	var unit := TestStubs.FakeUnit.new()
	var loc := Location.new()
	loc.loc_name = "Some Location"
	loc.coord = Vector2i(1, 1)

	var task := Task.new()
	task.id = &"abstract_task"
	task.title = "Abstract Task"
	task.event_type = "explore"
	# NO target_coord or target_id
	task.initialize()

	var stage := Stage.new()
	stage.active_tasks = [task]

	var objective := Objective.new()
	objective.current_stage = stage
	objective.is_active = true

	var task_manager := TestStubs.FakeTaskManager.new()
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider := LocationActionProvider.new()
	var actions: Array[UnitAction] = []
	provider.append_location_action(actions, unit, Vector2i(1, 1), [], {})

	assert_int(actions.size()).is_equal(0)

	unit.free()
	loc.free()
