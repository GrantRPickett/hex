# This test file has been updated to match the refactored InputHandler (decoupled from grid, action-based).
extends GdUnitTestSuite

var _handler: InputHandler

# Define the actions the InputHandler will be listening for.
# We add them to the InputMap for the duration of the test.
const ACTIONS = [
	"move_q", "move_w", "move_e", "move_a", "move_s", "move_d",
	"cycle_next", "cycle_prev",
	"toggle_free_cam",
	"camera_zoom_in", "camera_zoom_out",
	"ui_select", # For primary action
	"secondary_action"
]

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
	assert_that(_handler).is_instance_of(InputHandler)
	# Add the handler to the scene tree so it can use get_tree().
	add_child(_handler)
	# Wait a frame for the node to be fully integrated into the tree.
	await get_tree().process_frame

func after_test() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)

func test_move_action_emits_move_requested() -> void:
	var monitor := monitor_signals(_handler)

	# The new handler is generic, so we just test one move action.
	var event = InputEventAction.new()
	event.action = "move_q"
	event.pressed = true

	_handler._unhandled_input(event)

	await assert_signal(monitor).is_emitted("move_requested", ["move_q"])


func test_cycle_action_emits_selection_cycle_requested() -> void:
	var monitor := monitor_signals(_handler)

	var event = InputEventAction.new()
	event.action = "cycle_next" # Action was renamed from "select_next"
	event.pressed = true

	_handler._unhandled_input(event)

	await assert_signal(monitor).is_emitted("selection_cycle_requested", [1])


func test_primary_action_emits_primary_action_at() -> void:
	var monitor := monitor_signals(_handler)

	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	mouse_event.position = Vector2(123, 456)

	# The test now relies on the InputMap linking the mouse event to the "ui_select" action.
	_handler._unhandled_input(mouse_event)

	# The refactored handler should emit the screen position.
	await assert_signal(monitor).is_emitted("primary_action_at", [mouse_event.position])

func test_zoom_action_emits_zoom_requested() -> void:
	var monitor := monitor_signals(_handler)

	var event = InputEventAction.new()
	event.action = "camera_zoom_in"
	event.pressed = true

	_handler._unhandled_input(event)

	await assert_signal(monitor).is_emitted("zoom_requested", [1])