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
const WAIT_ACTION := InputActions.WAIT_ACTION
const ZOOM_IN_ACTION := InputActions.CAMERA_ZOOM_IN
const ZOOM_OUT_ACTION := InputActions.CAMERA_ZOOM_OUT
const FREE_CAM_TOGGLE_ACTION := InputActions.FREE_CAM_TOGGLE
const CYCLE_NEXT_ACTION := InputActions.SELECTION_CYCLE_NEXT
const CYCLE_PREV_ACTION := InputActions.SELECTION_CYCLE_PREV
const TOGGLE_ENEMY_RANGE_ACTION := InputActions.TOGGLE_ENEMY_RANGE
const CONFIRM_MOVE_ACTION := InputActions.CONFIRM_MOVE
const CANCEL_MOVE_ACTION := InputActions.CANCEL_MOVE
const UI_NAV_TOGGLE_ACTION := InputActions.UI_NAV_TOGGLE
const AUTO_BATTLE_TOGGLE_ACTION := InputActions.AUTO_BATTLE_TOGGLE
const CAMERA_PAN_UP := GameConstants.Inputs.CAMERA_PAN_UP
const CAMERA_PAN_DOWN := GameConstants.Inputs.CAMERA_PAN_DOWN
const CAMERA_PAN_LEFT := GameConstants.Inputs.CAMERA_PAN_LEFT
const CAMERA_PAN_RIGHT := GameConstants.Inputs.CAMERA_PAN_RIGHT


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
# Emitted when the player requests to end the selected unit's turn without moving.
signal wait_requested
# Emitted to toggle the free camera state.
signal free_cam_toggle_requested
# Emitted for zooming actions (e.g., mouse wheel).
signal zoom_requested(direction: int)
# Emitted for unhandled input events that the camera might want to process.
signal camera_input_requested(event: InputEvent)
# Emitted to toggle the enemy range visualization.
signal toggle_enemy_range_requested
# Emitted to confirm a tentative move.
signal confirm_move_requested
# Emitted to cancel a tentative move.
signal cancel_move_requested
signal ui_nav_toggle_requested
signal auto_battle_toggle_requested
# Emitted when the mouse is dragged while the primary button is held.
signal drag_interacted(relative_delta: Vector2)
# Emitted for camera panning requests (keyboard or controller).
signal pan_requested(direction: Vector2, delta: float)


# Emitted continuously while a joystick is held beyond its deadzone.
signal joy_axis_held(axis: Vector2, delta: float)
signal joy_aim_held(axis: Vector2, delta: float)


# --- Constants ---

const JOY_DEADZONE := 0.4
const JOY_REPEAT_DELAY := 0.2


# --- Private State ---

var _joy_axis := Vector2.ZERO
var _joy_repeat_timer := 0.0
var _aim_axis := Vector2.ZERO
var _move_actions: Array[StringName] = []
var _selection_actions: Array[StringName] = []
var _ui_nav_mode := false
var _is_dragging := false
var _drag_start_pos := Vector2.ZERO
var _primary_mouse_pressed := false
const DRAG_THRESHOLD := 5.0


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
	if _should_ignore_input(event):
		return

	if _handle_ui_nav_toggle(event):
		return

	if _handle_auto_battle_toggle(event):
		return

	if _ui_nav_mode:
		return

	if _handle_camera_interception(event):
		return

	if _handle_drag(event):
		return

	_handle_core_gameplay_inputs(event)

func _handle_drag(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_primary_mouse_pressed = event.pressed
		if event.pressed:
			_drag_start_pos = event.position
			_is_dragging = false
		else:
			_is_dragging = false
		return false # Allow click to pass through to _handle_core_gameplay_inputs

	if event is InputEventMouseMotion:
		if _primary_mouse_pressed:
			if not _is_dragging:
				if event.position.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
					_is_dragging = true
			
			if _is_dragging:
				drag_interacted.emit(event.relative)
				return true # Drag consumed
	
	return false

func _should_ignore_input(event: InputEvent) -> bool:
	var tree := get_tree() if is_inside_tree() else null
	if tree and tree.paused and not event.is_action("ui_cancel"):
		return true
	return false

func _handle_auto_battle_toggle(event: InputEvent) -> bool:
	if _event_matches_action(event, AUTO_BATTLE_TOGGLE_ACTION):
		auto_battle_toggle_requested.emit()
		_mark_input_handled()
		return true
	return false

func _handle_camera_interception(event: InputEvent) -> bool:
	camera_input_requested.emit(event)
	var viewport := get_viewport()
	return viewport != null and viewport.is_input_handled()

func _handle_core_gameplay_inputs(event: InputEvent) -> void:
	if _handle_gameplay_actions(event): return
	if _handle_selection_actions(event): return
	if _handle_camera_actions(event): return

	_handle_joypad_motion(event)



# --- Public Methods ---

func reset_joy_state() -> void:
	_joy_axis = Vector2.ZERO
	_joy_repeat_timer = 0.0

func set_ui_navigation_mode(enabled: bool) -> void:
	_ui_nav_mode = enabled
	if not enabled:
		reset_joy_state()

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
	if _ui_nav_mode:
		return false
	#GameLogger.debug(GameLogger.Category.SYSTEM, "DBG _handle_gameplay_actions event=", event)
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

	if _event_matches_action(event, CONFIRM_MOVE_ACTION):
		confirm_move_requested.emit()
		_mark_input_handled()
		return true

	if _event_matches_action(event, CANCEL_MOVE_ACTION):
		cancel_move_requested.emit()
		_mark_input_handled()
		return true

	if _event_matches_action(event, WAIT_ACTION):
		wait_requested.emit()
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
	if _ui_nav_mode:
		return false
	# Cycle selection
	#GameLogger.debug(GameLogger.Category.SYSTEM, "DBG _handle_selection_actions event=", event)
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
			var index_str: String = action_name.trim_prefix(DIRECT_SELECTION_PREFIX)
			if index_str.is_valid_int():
				var index: int = index_str.to_int() - 1
				select_index_requested.emit(index)
				_mark_input_handled()
				return true

	return false


# Handles camera-specific controls like zooming and mode toggling.
func _handle_camera_actions(event: InputEvent) -> bool:
	if _ui_nav_mode:
		return false
	#GameLogger.debug(GameLogger.Category.SYSTEM, "DBG _handle_camera_actions event=", event)
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

	# Toggling enemy range
	if _event_matches_action(event, TOGGLE_ENEMY_RANGE_ACTION):
		toggle_enemy_range_requested.emit()
		_mark_input_handled()
		return true

	if _handle_camera_pan_actions(event): return true
	return false


func _handle_camera_pan_actions(event: InputEvent) -> bool:
	var dir := Vector2.ZERO
	if _event_matches_action(event, CAMERA_PAN_UP): dir.y -= 1
	if _event_matches_action(event, CAMERA_PAN_DOWN): dir.y += 1
	if _event_matches_action(event, CAMERA_PAN_LEFT): dir.x -= 1
	if _event_matches_action(event, CAMERA_PAN_RIGHT): dir.x += 1
	
	if dir != Vector2.ZERO:
		pan_requested.emit(dir.normalized(), get_process_delta_time())
		_mark_input_handled()
		return true
	return false


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()


func _event_matches_action(event: InputEvent, action: StringName) -> bool:
	if event is InputEventAction:
		return event.pressed and event.action == action
	return event.is_action_pressed(action)


# Updates the internal state of the joystick's left stick axis.
func _handle_joypad_motion(event: InputEvent) -> void:
	if _ui_nav_mode:
		return
	if event is InputEventJoypadMotion:
		# Left stick for movement repeat
		if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			if event.axis == JOY_AXIS_LEFT_X:
				_joy_axis.x = event.axis_value
			else:
				_joy_axis.y = event.axis_value
			if _joy_axis.length() < JOY_DEADZONE:
				_joy_axis = Vector2.ZERO
		# Right stick for aiming/cursor
		if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
			if event.axis == JOY_AXIS_RIGHT_X:
				_aim_axis.x = event.axis_value
			else:
				_aim_axis.y = event.axis_value
			if _aim_axis.length() < JOY_DEADZONE:
				_aim_axis = Vector2.ZERO


# Processes the current joystick state to emit held signals.
func _process_joy_axis(delta: float) -> void:
	if _ui_nav_mode:
		return
	if _joy_repeat_timer > 0.0:
		_joy_repeat_timer = max(_joy_repeat_timer - delta, 0.0)

	if _joy_axis.length() >= JOY_DEADZONE and _joy_repeat_timer <= 0.0:
		joy_axis_held.emit(_joy_axis, delta)
		_joy_repeat_timer = JOY_REPEAT_DELAY
	elif _joy_axis.length() < JOY_DEADZONE:
		_joy_repeat_timer = 0.0

	# Emit right stick aim continuously when above deadzone
	if _aim_axis.length() >= JOY_DEADZONE:
		joy_aim_held.emit(_aim_axis, delta)
		pan_requested.emit(_aim_axis, delta)

func _handle_ui_nav_toggle(event: InputEvent) -> bool:
	if _event_matches_action(event, UI_NAV_TOGGLE_ACTION):
		ui_nav_toggle_requested.emit()
		_mark_input_handled()
		return true
	return false
