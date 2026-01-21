# This test file has been updated to match the refactored InputHandler (decoupled from grid, action-based).
extends GdUnitTestSuite

var _handler: InputHandler

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = StringName(action)
	ev.pressed = true
	return ev

func _send_input(event: InputEvent) -> void:
	var tree := get_tree()
	if tree:
		tree.paused = false
	_handler._unhandled_input(event)

# Define the actions the InputHandler will be listening for.
# We add them to the InputMap for the duration of the test.
const ACTIONS = [
	"move_q", "move_w", "move_e", "move_a", "move_s", "move_d",
	"cycle_next", "cycle_prev",
	"toggle_free_cam",
	"camera_zoom_in", "camera_zoom_out",
	"ui_select", # For primary action
	"secondary_action",
	"toggle_enemy_range"
]

const REFRESH_TEST_ACTION := "move_refresh_cache"

func before_test() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	# Map left-click to ui_select for testing primary_action_at
	var left_click_event = InputEventMouseButton.new()
	left_click_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("ui_select", left_click_event)

	_handler = auto_free(InputHandler.new())
	# Ensure the handler is of the correct type before proceeding.
	assert_that(_handler is InputHandler).is_true()
	# Add the handler to the scene tree so it can use get_tree().
	add_child(_handler)
	# Wait a frame for the node to be fully integrated into the tree.
	await get_tree().process_frame
	var tree := get_tree()
	if tree:
		tree.paused = false

func after_test() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	if InputMap.has_action(REFRESH_TEST_ACTION):
		InputMap.erase_action(REFRESH_TEST_ACTION)

func test_move_action_emits_move_requested() -> void:
	var monitor := monitor_signals(_handler)

	# The new handler is generic, so we just test one move action.
	_send_input(_action_event("move_q"))

	await assert_signal(monitor).is_emitted("move_requested", ["move_q"])


func test_cycle_action_emits_selection_cycle_requested() -> void:
	var monitor := monitor_signals(_handler)

	_send_input(_action_event("cycle_next"))

	await assert_signal(monitor).is_emitted("selection_cycle_requested", [1])


func test_primary_action_emits_primary_action_at() -> void:
	var monitor := monitor_signals(_handler)

	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	mouse_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse_event.position = Vector2(123, 456)

	# The test now relies on the InputMap linking the mouse event to the "ui_select" action.
	_send_input(mouse_event)

	# The refactored handler should emit the screen position.
	await assert_signal(monitor).is_emitted("primary_action_at", [mouse_event.position])

func test_zoom_action_emits_zoom_requested() -> void:
	var monitor := monitor_signals(_handler)

	_send_input(_action_event("camera_zoom_in"))

	await assert_signal(monitor).is_emitted("zoom_requested", [1])

func test_refresh_action_cache_picks_up_new_actions() -> void:
	var action_name := REFRESH_TEST_ACTION
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	_handler.refresh_action_cache()
	assert_bool(_handler._move_actions.has(StringName(action_name))).is_false()

	InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_T
	InputMap.action_add_event(action_name, key_event)
	assert_bool(_handler._move_actions.has(StringName(action_name))).is_false()

	_handler.refresh_action_cache()
	assert_bool(_handler._move_actions.has(StringName(action_name))).is_true()

func test_reset_joy_state_clears_axis() -> void:
	_handler._joy_axis = Vector2(1, 2)
	_handler._joy_repeat_timer = 0.5

	_handler.reset_joy_state()

	assert_that(_handler._joy_axis).is_equal(Vector2.ZERO)
	assert_that(_handler._joy_repeat_timer).is_equal(0.0)

func test_toggle_enemy_range_requested_emitted() -> void:
	var monitor := monitor_signals(_handler)

	_send_input(_action_event("toggle_enemy_range"))

	await assert_signal(monitor).is_emitted("toggle_enemy_range_requested")
