extends GdUnitTestSuite

const WeatherPanelScript = preload("res://GUI/weather_panel.gd")
const PauseHandlerScript = preload("res://Menus/pause_handler.gd")
const AimCursorScript = preload("res://GUI/HUD/aim_cursor.gd")
const HUDHoverServiceScript = preload("res://GUI/HUD/hud_hover_service.gd")

func _add_and_free(node: Node) -> Node:
	add_child(node)
	return auto_free(node)

# --- WeatherPanel ---
func test_weather_panel_update_compass() -> void:
	var wp: WeatherPanelScript = WeatherPanelScript.new()
	var compass: Label = Label.new()
	compass.name = "CompassLabel"
	wp.add_child(compass)
	wp._compass_label = compass
	_add_and_free(wp)

	wp.update_compass(0.0)
	assert_str(compass.text).is_equal("N")

	wp.update_compass(PI / 3.0) # 60 degrees, NE
	assert_str(compass.text).is_equal("NE")

# --- PauseHandler ---
func test_pause_handler_show_pause_menu() -> void:
	var ph: PauseHandlerScript = PauseHandlerScript.new()
	_add_and_free(ph)

	assert_bool(ph.is_paused()).is_false()
	# Because load() on FilePaths inside PauseHandler might fail if scenes don't exist in testing,
	# We just do a smoke test to ensure no hard crash if file is missing, or catch if it does.
	# Actually, since scenes do exist in res://, this should work.
	ph.show_pause_menu()
	assert_bool(ph.is_paused()).is_true()

	# Hiding it should free menu
	ph._hide_pause_menu()
	assert_bool(ph.is_paused()).is_false()

# --- AimCursor ---
func test_aim_cursor_connect_input_handler() -> void:
	var ac: AimCursorScript = AimCursorScript.new()
	_add_and_free(ac)

	var handler: InputHandler = InputHandler.new()
	ac.connect_input_handler(handler)

	# Should be connected now
	assert_bool(handler.joy_aim_held.get_connections().size() > 0).is_true()
	handler.free()

class FakeHUDController extends Node2D:
	pass
# --- HUDHoverService ---
func test_hud_hover_service_process_hover() -> void:
	var svc: HUDHoverServiceScript = HUDHoverServiceScript.new()
	_add_and_free(svc)

	# Pass an invalid controller to test safe failure
	svc.setup(FakeHUDController.new())
	svc.process_hover()
	# Just verifies no crash without aim cursor or mouse

# --- HUDController ---
const HUDControllerScript = preload("res://GUI/HUD/hud_controller.gd")

func test_hud_controller_handle_actions_updated() -> void:
	var h: HUDControllerScript = HUDControllerScript.new()
	_add_and_free(h)

	var sig_called = [false]
	h.actions_updated.connect(func(_u, _t, _um): sig_called[0] = true)

	h.handle_actions_updated(null, null, null)
	assert_bool(sig_called[0]).is_true()

func test_hud_controller_refresh_after_state_restore() -> void:
	var h: HUDControllerScript = HUDControllerScript.new()
	_add_and_free(h)

	# Call it without setup, shouldn't crash
	h.refresh_after_state_restore()
