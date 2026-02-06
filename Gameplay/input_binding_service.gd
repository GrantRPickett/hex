class_name InputBindingService
extends RefCounted

const InputActions := preload("res://Resources/input_actions.gd")
const CONFIG_PATH := "user://input_bindings.cfg"

func apply_bindings(_controls: Node, _input_mapper: Node) -> void:
	var config = ConfigFile.new()
	config.load(CONFIG_PATH)

	var defaults: Array[Dictionary] = []
	defaults.append_array(InputActions.MOVEMENT_DEFAULTS)
	defaults.append_array(InputActions.INTERACTION_DEFAULTS)
	defaults.append_array(InputActions.CAMERA_DEFAULTS)
	defaults.append_array(InputActions.SELECTION_DEFAULTS)
	defaults.append_array(InputActions.PAUSE_DEFAULTS)
	defaults.append_array(InputActions.VISUAL_DEFAULTS)

	for entry in defaults:
		var action: String = entry["action"]
		if not InputMap.has_action(action):
			InputMap.add_action(action)

		InputMap.action_erase_events(action)

		var keys: Array = entry.get("keys", [])
		var joy_buttons: Array = entry.get("joy_buttons", [])
		var mouse_buttons: Array = entry.get("mouse_buttons", [])

		if config.has_section(action):
			keys = config.get_value(action, "keys", keys)
			joy_buttons = config.get_value(action, "joy_buttons", joy_buttons)
			mouse_buttons = config.get_value(action, "mouse_buttons", mouse_buttons)

		_register_events(action, keys, joy_buttons, mouse_buttons)

		if action == InputActions.PRIMARY_ACTION:
			var dialogue_action : String = InputActions.DIALOGIC_DEFAULT_ACTION
			if dialogue_action != "":
				if not InputMap.has_action(dialogue_action):
					InputMap.add_action(dialogue_action)
				InputMap.action_erase_events(dialogue_action)
				_register_events(dialogue_action, keys, joy_buttons, mouse_buttons)

func save_bindings(action: String, keys: Array, joy_buttons: Array, mouse_buttons: Array) -> void:
	var config = ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(action, "keys", keys)
	config.set_value(action, "joy_buttons", joy_buttons)
	config.set_value(action, "mouse_buttons", mouse_buttons)

	config.save(CONFIG_PATH)

	InputMap.action_erase_events(action)
	_register_events(action, keys, joy_buttons, mouse_buttons)

func restore_defaults() -> void:
	var config = ConfigFile.new()
	config.save(CONFIG_PATH) # Clear file
	apply_bindings(null, null)

func _register_events(action: String, keys: Array, joy_buttons: Array, mouse_buttons: Array) -> void:
	for k in keys:
		var event = InputEventKey.new()
		event.physical_keycode = k as Key
		InputMap.action_add_event(action, event)

	for m in mouse_buttons:
		var event = InputEventMouseButton.new()
		event.button_index = m as MouseButton
		InputMap.action_add_event(action, event)

	for j in joy_buttons:
		var event
		# Heuristic: Triggers (4, 5) are axes if used in movement actions, otherwise buttons (Back/Guide)
		# This handles the default mapping where move_a/move_d use triggers.
		var is_trigger_axis = (j == JOY_AXIS_TRIGGER_LEFT or j == JOY_AXIS_TRIGGER_RIGHT) and action.begins_with("move_")

		if is_trigger_axis:
			event = InputEventJoypadMotion.new()
			event.axis = j as JoyAxis
			event.axis_value = 1.0
		else:
			event = InputEventJoypadButton.new()
			event.button_index = j as JoyButton

		InputMap.action_add_event(action, event)