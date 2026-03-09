extends GdUnitTestSuite

const HUDControllerClass = preload("res://GUI/HUD/hud_controller.gd")

func test_handle_dialogue_finished() -> void:
	var ctrl = auto_free(HUDControllerClass.new())

	# Just verifying it doesn't crash since it updates some internals
	ctrl.handle_dialogue_finished("test")

func test_hud_signal_connector_connect_all() -> void:
	var hud_sc = auto_free(preload("res://GUI/HUD/hud_signal_connector.gd").new())

	# Very minimal setup to avoid null checks
	var ctrl = auto_free(HUDControllerClass.new())
	var dict = {
		"task_manager": null,
		"unit_manager": null,
		"unit_controller": null,
		"turn_controller": null,
		"hud": null
	}
	hud_sc.setup(ctrl, dict as GameState, null)
	hud_sc.connect_all()
