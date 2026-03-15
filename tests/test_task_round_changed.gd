extends GdUnitTestSuite

func test_task_controller_receives_round_changed() -> void:
	var services: Dictionary = {}
	var state: GameState = GameState.new(services)
	state.task_manager = TaskManager.new()
	state.turn_controller = TurnController.new()

	var controller := TaskController.new()
	controller.setup(state)

	var called: bool = false
	controller.task_reached.connect(func(): called = true)

	# Stub active objective to observe round_changed dispatch without NPE
	var obj := Objective.new()
	obj.is_active = true
	obj.current_stage = Stage.new()
	state.task_manager.set_level_and_objective(null, obj)

	# Spy on objective.handle_event by overriding method
	var received := false
	#todo idk the invalid code that was generated that didn't parse needs a replacement
	# Trigger round advance on TurnController
	state.turn_controller.reset()
	state.turn_controller.rebuild_turn_roster()
	# Force start_new_round path
	state.turn_controller._turn_queue.clear()
	state.turn_controller.start_next_turn()

	assert_bool(received).is_true()
