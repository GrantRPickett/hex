extends GdUnitTestSuite

const TaskControllerClass = preload("res://Gameplay/narrative/task/task_controller.gd")
const LevelClass = preload("res://level/level.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_task_controller_finish_setup() -> void:
	var ctrl = auto_free(TaskControllerClass.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var ds = auto_free(Stubs.FakeDialogueActionService.new()) # using any stub as placeholder
	var dt = auto_free(Node.new()) # dummy state
	var dict = {
		"task_manager": tm,
		"unit_manager": null,
		"unit_controller": null,
		"turn_controller": null,
		"loot_manager": null,
		"combat_system": null,
		"location_service": null,
		"dialogue_action_service": ds
	}

	ctrl.setup(dict as GameState)
	assert_bool(ctrl._setup_finished).is_false()
	ctrl.finish_setup()
	assert_bool(ctrl._setup_finished).is_true()

func test_task_controller_bootstrap_and_activate() -> void:
	var ctrl = auto_free(TaskControllerClass.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var dict = {"task_manager": tm, "unit_manager": null, "unit_controller": null, "turn_controller": null, "loot_manager": null, "combat_system": null, "location_service": null}

	ctrl.setup(dict as GameState)

	var lvl = auto_free(LevelClass.new())
	ctrl.bootstrap_level(lvl)
	assert_bool(ctrl._setup_finished).is_false()

	# just ensure it doesn't crash to call activate
	ctrl.activate_initial_stage()

func test_task_controller_on_task_completed() -> void:
	var ctrl = auto_free(TaskControllerClass.new())
	ctrl.on_task_completed(0, 0, null)
	# Asserts no crash with null state

func test_task_controller_is_narrative_blocking() -> void:
	var ctrl = auto_free(TaskControllerClass.new())
	var dict = {"task_manager": null, "unit_manager": null, "unit_controller": null, "turn_controller": null, "loot_manager": null, "combat_system": null, "location_service": null}

	ctrl.setup(dict as GameState)
	assert_bool(ctrl.is_narrative_blocking()).is_false()
