extends GdUnitTestSuite

const LocationActionProviderScript = preload("res://Gameplay/targets/location_action_provider.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_location_action_provider_append_location_action() -> void:
	var provider = auto_free(LocationActionProviderScript.new())
	var actions: Array = []
	var unit = auto_free(Unit.new())
	var manager = auto_free(Stubs.FakeTaskManager.new())
	unit.set_task_manager(manager)
	
	var objective = auto_free(Objective.new())
	var stage = auto_free(Stage.new())
	var task = auto_free(Task.new())
	task.target_kind = GameConstants.Tasks.KIND_LOCATION
	task.target_coord = Vector2i(1, 1)
	task.status = Task.Status.ACTIVE
	task.event_type = GameConstants.TaskEvents.EXPLORE
	stage.active_tasks = [task]
	objective.current_stage = stage
	manager.set_active_objective(objective)
	
	var loc = auto_free(Location.new())
	loc.loc_name = "Test Loc"
	manager.set_location(Vector2i(1, 1), loc)

	provider.append_location_action(actions, unit, Vector2i(0, 0), [Vector2i(1, 1)], {Vector2i(1, 1): {"cost": 1}})
	assert_int(actions.size()).is_equal(1)
	assert_bool(actions[0].type == GameConstants.ActionType.EXPLORE).is_true()
