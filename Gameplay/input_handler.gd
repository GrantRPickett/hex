# Handles raw player input and translates it into gameplay-relevant signals.
# This class is intended to be decoupled from game state (like the grid or camera).
# It emits signals based on abstract actions (e.g., "primary_action") rather than
# specific hardware inputs (e.g., "left mouse button").
# The mapping of hardware inputs to these actions should be done in Godot's Input Map.
class_name InputHandler
extends Node

const MOVE_ACTION_PREFIX := InputActions.MOVEMENT_PREFIX
const DIRECT_SELECTION_PREFIX := InputActions.DIRECT_SELECTION_PREFIX
const PRIMARY_ACTION := InputActions.PRIMARY_ACTION
const SECONDARY_ACTION := InputActions.SECONDARY_ACTION
const ZOOM_IN_ACTION := InputActions.CAMERA_ZOOM_IN
const ZOOM_OUT_ACTION := InputActions.CAMERA_ZOOM_OUT
const FREE_CAM_TOGGLE_ACTION := InputActions.FREE_CAM_TOGGLE
const CYCLE_NEXT_ACTION := InputActions.SELECTION_CYCLE_NEXT
const CYCLE_PREV_ACTION := InputActions.SELECTION_CYCLE_PREV

# Emitted for directional movement commands, passing the specific action triggered.
signal move_requested(action_name: String)
# Emitted for cycling through selectable items.
signal selection_cycle_requested(direction: int)
# Emitted for direct selection by index.
signal select_index_requested(index: int)
# Emitted when the primary action (e.g., left-click) occurs, with screen position.
signal primary_action_at(screen_pos: Vector2)
# Emitted when the secondary action (e.g., right-click) occurs, with screen position.
signal secondary_action_at(screen_pos: Vector2)
# Emitted to toggle the free camera state.
signal free_cam_toggle_requested
# Emitted for zooming actions (e.g., mouse wheel).
signal zoom_requested(direction: int)
# Emitted for unhandled input events that the camera might want to process.
signal camera_input_requested(event: InputEvent)
# Emitted continuously while a joystick is held beyond its deadzone.
signal joy_axis_held(axis: Vector2, delta: float)


# --- Constants ---

const JOY_DEADZONE := 0.4
const JOY_REPEAT_DELAY := 0.2


# --- Private State ---

var _joy_axis := Vector2.ZERO
var _joy_repeat_timer := 0.0
var _move_actions: Array[StringName] = []
var _selection_actions: Array[StringName] = []


# --- Engine Callbacks ---

func _ready() -> void:
	# This node should not pause, as it might need to handle input to un-pause the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	set_physics_process(true)

	refresh_action_cache()


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		reset_joy_state()

func _physics_process(delta: float) -> void:
	# Joypad axis events are not guaranteed to be sent every frame, so we process
	# the last known axis value in _physics_process to get smooth, continuous movement.
	if get_tree().paused:
		return
	_process_joy_axis(delta)


func _unhandled_input(event: InputEvent) -> void:
	# If the game is paused, we only process inputs that are marked as "Process When Paused".
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree and tree.paused and not event.is_action("ui_cancel"): # Assuming 'ui_cancel' is used for un-pausing.
		return

	var viewport := get_viewport()
	var was_handled := false
	if viewport:
		was_handled = viewport.is_input_handled()
	# Allow the camera to intercept input first (e.g., for free-look rotation).
	camera_input_requested.emit(event)
	if viewport and not was_handled and viewport.is_input_handled():
		return # The camera used the input, so we stop further processing.

	# We check for actions in a specific order to prevent conflicts (e.g., a gameplay
	# action that is also a UI action).
	if _handle_gameplay_actions(event): return
	if _handle_selection_actions(event): return
	if _handle_camera_actions(event): return

	_handle_joypad_motion(event)


# --- Public Methods ---

func reset_joy_state() -> void:
	_joy_axis = Vector2.ZERO
	_joy_repeat_timer = 0.0

func refresh_action_cache() -> void:
	_move_actions.clear()
	_selection_actions.clear()
	for action in InputMap.get_actions():
		var action_name := StringName(action)
		var action_str := String(action_name)
		if action_str.begins_with(MOVE_ACTION_PREFIX):
			_move_actions.append(action_name)
		elif action_str.begins_with(DIRECT_SELECTION_PREFIX):
			_selection_actions.append(action_name)


# --- Private Input Handlers ---
# Handles primary and secondary actions, and directional movement.
func _handle_gameplay_actions(event: InputEvent) -> bool:
	print_debug("DBG _handle_gameplay_actions event=", event)
	# Primary Action (e.g., Left Click)
	if _event_matches_action(event, PRIMARY_ACTION) and event is InputEventMouseButton:
		primary_action_at.emit(event.position)
		_mark_input_handled()
		return true

	# Secondary Action (e.g., Right Click)
	if _event_matches_action(event, SECONDARY_ACTION) and event is InputEventMouseButton:
		secondary_action_at.emit(event.position)
		_mark_input_handled()
		return true

	# Directional Movement
	# We check the action name prefix to handle all 'move_*' actions generically.
	for action_name in _move_actions:
		if _event_matches_action(event, action_name):
			move_requested.emit(action_name)
			_mark_input_handled()
			return true

	if event is InputEventAction and event.pressed:
		var action_id := str(event.action)
		if action_id.begins_with(MOVE_ACTION_PREFIX):
			move_requested.emit(action_id)
			_mark_input_handled()
			return true

	return false


# Handles cycling through units/items and direct selection.
func _handle_selection_actions(event: InputEvent) -> bool:
	# Cycle selection
	print_debug("DBG _handle_selection_actions event=", event)
	if _event_matches_action(event, CYCLE_NEXT_ACTION):
		selection_cycle_requested.emit(1)
		_mark_input_handled()
		return true
	if _event_matches_action(event, CYCLE_PREV_ACTION):
		selection_cycle_requested.emit(-1)
		_mark_input_handled()
		return true

	# Direct selection (e.g., using number keys)
	# This is more dynamic than a hardcoded range. It checks for all actions
	# that exist in the InputMap with the DIRECT_SELECTION_PREFIX prefix.
	for action_name in _selection_actions:
		if _event_matches_action(event, action_name):
			var index_str = action_name.trim_prefix(DIRECT_SELECTION_PREFIX)
			if index_str.is_valid_int():
				var index = index_str.to_int() - 1
				select_index_requested.emit(index)
				_mark_input_handled()
				return true

	return false


# Handles camera-specific controls like zooming and mode toggling.
func _handle_camera_actions(event: InputEvent) -> bool:
	print_debug("DBG _handle_camera_actions event=", event)
	# Zooming
	if _event_matches_action(event, ZOOM_IN_ACTION):
		zoom_requested.emit(1)
		_mark_input_handled()
		return true
	if _event_matches_action(event, ZOOM_OUT_ACTION):
		zoom_requested.emit(-1)
		_mark_input_handled()
		return true

	# Toggling free camera
	if _event_matches_action(event, FREE_CAM_TOGGLE_ACTION):
		free_cam_toggle_requested.emit()
		_mark_input_handled()
		return true

	return false


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()


func _event_matches_action(event: InputEvent, action: StringName) -> bool:
	var action_name := StringName(action)
	if event is InputEventAction:
		var event_action: StringName = event.action if event.action is StringName else StringName(event.action)
		return event.pressed and event_action == action_name
	return event.is_action_pressed(action_name)


# Updates the internal state of the joystick's left stick axis.
func _handle_joypad_motion(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		if event.axis == JOY_AXIS_LEFT_X:
			_joy_axis.x = event.axis_value
		else:
			_joy_axis.y = event.axis_value
		# If stick returns to center, reset immediately.
		if _joy_axis.length() < JOY_DEADZONE:
			_joy_axis = Vector2.ZERO


# Processes the current joystick state to emit held signals.
func _process_joy_axis(delta: float) -> void:
	if _joy_repeat_timer > 0.0:
		_joy_repeat_timer = max(_joy_repeat_timer - delta, 0.0)

	if _joy_axis.length() >= JOY_DEADZONE and _joy_repeat_timer <= 0.0:
		joy_axis_held.emit(_joy_axis, delta)
		_joy_repeat_timer = JOY_REPEAT_DELAY
	elif _joy_axis.length() < JOY_DEADZONE:
		_joy_repeat_timer = 0.0
