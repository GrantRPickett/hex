extends GdUnitTestSuite

# Standardize reusable paths for action panel behavior tests
# This test focuses on location-based exploration.

const _LocationActionProvider = preload("res://Gameplay/targets/location_action_provider.gd")
const _TestStubs = preload("res://tests/fixtures/test_stubs.gd")
const _Location = preload("res://Gameplay/targets/location.gd")
const _Task = preload("res://Gameplay/narrative/task/task.gd")
const _Stage = preload("res://Gameplay/narrative/task/objective_stage.gd")
const _Objective = preload("res://Gameplay/narrative/task/objective.gd")
const _Unit = preload("res://Gameplay/targets/unit.gd")

func test_explore_action_added() -> void:
	var unit: _Unit = auto_free(_TestStubs.FakeUnit.new())
	unit.set_attribute_values({"grit": 10})

	var loc: _Location = auto_free(_Location.new())
	loc.loc_name = "Ancient Ruin"
	loc.coord = Vector2i(1, 1)

	var task: _Task = auto_free(_Task.new())
	task.id = &"explore_ruin"
	task.title = "Explore Ruin"
	task.event_type = "explore"
	task.target_kind = GameConstants.Tasks.KIND_LOCATION
	task.target_coord = Vector2i(1, 1)
	task.effort_required = 5
	task.initialize()

	var stage: _Stage = auto_free(_Stage.new())
	stage.active_tasks = [task]

	var objective: _Objective = auto_free(_Objective.new())
	objective.current_stage = stage
	objective.is_active = true

	var task_manager: _TestStubs.FakeTaskManager = auto_free(_TestStubs.FakeTaskManager.new())
	task_manager.set_location(Vector2i(1, 1), loc)
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider: _LocationActionProvider = auto_free(_LocationActionProvider.new())
	var actions: Array[PlayerAction] = []
	# Passing empty reachable arrays for this test
	provider.append_location_action(actions, unit, Vector2i(1, 1), [], {})

	assert_int(actions.size()).is_equal(1)
	assert_int(actions[0].type).is_equal(PlayerAction.Type.EXPLORE)
	# Summary label params
	assert_int(actions[0].label_params.get("near")).is_equal(1)
	assert_int(actions[0].label_params.get("far")).is_equal(0)
	assert_that(actions[0].target).is_equal(loc)


func test_reachable_explore_action_added() -> void:
	var unit: _Unit = auto_free(_TestStubs.FakeUnit.new())
	unit.set_attribute_values({"grit": 10})

	var loc: _Location = auto_free(_Location.new())
	loc.loc_name = "Distant Ruin"
	loc.coord = Vector2i(5, 5)

	var task: _Task = auto_free(_Task.new())
	task.id = &"explore_ruin"
	task.title = "Explore Ruin"
	task.event_type = "explore"
	task.target_kind = GameConstants.Tasks.KIND_LOCATION
	task.target_coord = Vector2i(5, 5)
	task.effort_required = 5
	task.initialize()

	var stage: _Stage = auto_free(_Stage.new())
	stage.active_tasks = [task]

	var objective: _Objective = auto_free(_Objective.new())
	objective.current_stage = stage
	objective.is_active = true

	var task_manager: _TestStubs.FakeTaskManager = auto_free(_TestStubs.FakeTaskManager.new())
	task_manager.set_location(Vector2i(5, 5), loc)
	task_manager.set_active_objective(objective)

	unit.set_task_manager(task_manager)

	var provider: _LocationActionProvider = auto_free(_LocationActionProvider.new())
	var actions: Array[PlayerAction] = []
	# Origin is 1,1; Ruin is reachable at 5,5
	provider.append_location_action(actions, unit, Vector2i(1, 1), [Vector2i(5, 5)], {Vector2i(5, 5): 3})

	assert_int(actions.size()).is_equal(1)
	assert_int(actions[0].type).is_equal(PlayerAction.Type.EXPLORE)
	assert_int(actions[0].label_params.get("near")).is_equal(0)
	assert_int(actions[0].label_params.get("far")).is_equal(1)
	assert_int(actions[0].reachable_targets.size()).is_equal(1)
	assert_that(actions[0].reachable_targets[0]).is_equal(loc)


func test_abstract_task_no_action() -> void:
	var unit: _Unit = auto_free(_TestStubs.FakeUnit.new())
	var loc: _Location = auto_free(_Location.new())
	loc.coord = Vector2i(1, 1)

	var task: _Task = auto_free(_Task.new())
	task.id = &"abstract_task"
	task.target_coord = GameConstants.INVALID_COORD # No specific location
	task.initialize()

	var stage: _Stage = auto_free(_Stage.new())
	stage.active_tasks = [task]

	var objective: _Objective = auto_free(_Objective.new())
	objective.current_stage = stage
	objective.is_active = true

	var task_manager: _TestStubs.FakeTaskManager = auto_free(_TestStubs.FakeTaskManager.new())
	task_manager.set_active_objective(objective)
	unit.set_task_manager(task_manager)

	var provider: _LocationActionProvider = auto_free(_LocationActionProvider.new())
	var actions: Array[PlayerAction] = []
	provider.append_location_action(actions, unit, Vector2i(1, 1), [], {})

	assert_int(actions.size()).is_equal(0)
