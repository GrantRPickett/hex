extends GdUnitTestSuite

const LevelStateControllerClass = preload("res://level/level_state_controller.gd")

func test_get_task_reached_state() -> void:
	var ctrl = auto_free(LevelStateControllerClass.new())
	var state: GameState = GameState.new({})
	# Test with no task_controller (returns false)
	ctrl.setup(state)
	assert_bool(ctrl.get_task_reached_state()).is_false()

func test_set_task_reached_state() -> void:
	var ctrl = auto_free(LevelStateControllerClass.new())
	ctrl.set_task_reached_state(true)
	assert_bool(ctrl._task_reached_state).is_true()

func test_update_safe_zone_ui() -> void:
	var ctrl = auto_free(LevelStateControllerClass.new())
	var state: GameState = GameState.new({})
	ctrl.setup(state)
	# Safely handles no HUD Controller
	ctrl.update_safe_zone_ui(true)

	# Try with a dummy HUD controller to ensure method called
	var hud_ctrl = auto_free(HUDController.new())
	state.hud_controller = hud_ctrl
	ctrl.update_safe_zone_ui(true)
	assert_bool(hud_ctrl._is_safe_zone_mode).is_true()
