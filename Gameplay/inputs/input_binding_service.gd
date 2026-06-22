class_name InputBindingService
extends RefCounted

const CONFIG_PATH := "user://input_bindings.cfg"

func apply_bindings(controls: Node, input_mapper: Node) -> void:
	if controls and input_mapper:
		_apply_from_controls(controls, input_mapper)
		return

	var config: ConfigFile = ConfigFile.new()
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

		var keys: Array[Key] = entry.get("keys", [])
		var joy_buttons: Array[JoyButton] = entry.get("joy_buttons", [])
		var mouse_buttons: Array[MouseButton] = entry.get("mouse_buttons", [])

		if config.has_section(action):
			keys = config.get_value(action, "keys", keys)
			joy_buttons = config.get_value(action, "joy_buttons", joy_buttons)
			mouse_buttons = config.get_value(action, "mouse_buttons", mouse_buttons)

		_register_events(action, keys, joy_buttons, mouse_buttons)


func save_bindings(action: String, keys: Array[Key], joy_buttons: Array[JoyButton], mouse_buttons: Array[MouseButton]) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(action, "keys", keys)
	config.set_value(action, "joy_buttons", joy_buttons)
	config.set_value(action, "mouse_buttons", mouse_buttons)

	config.save(CONFIG_PATH)

	InputMap.action_erase_events(action)
	_register_events(action, keys, joy_buttons, mouse_buttons)

func restore_defaults() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.save(CONFIG_PATH) # Clear file
	apply_bindings(null, null)

func _register_events(action: String, keys: Array, joy_buttons: Array, mouse_buttons: Array) -> void:
	for k in keys:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = k as Key
		InputMap.action_add_event(action, event)

	for m in mouse_buttons:
		var event: InputEventMouseButton = InputEventMouseButton.new()
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

func _apply_from_controls(controls: Node, input_mapper: Node) -> void:
	if not input_mapper or not input_mapper.has_method("apply_configs"):
		GameLogger.warning(GameLogger.Category.SYSTEM, "InputBindingService: InputMapper missing or invalid.")
		return

	_apply_action_group(controls, input_mapper, "move_actions", InputActions.MOVEMENT_DEFAULTS)
	_apply_action_group(controls, input_mapper, "interaction_actions", InputActions.INTERACTION_DEFAULTS)
	_apply_action_group(controls, input_mapper, "camera_actions", InputActions.CAMERA_DEFAULTS)
	_apply_action_group(controls, input_mapper, "selection_actions", InputActions.SELECTION_DEFAULTS)
	_apply_action_group(controls, input_mapper, "pause_actions", InputActions.PAUSE_DEFAULTS)
	_apply_action_group(controls, input_mapper, "visual_actions", InputActions.VISUAL_DEFAULTS)

func _apply_action_group(controls: Node, input_mapper: Node, property_name: String, fallback: Array) -> void:
	var params = fallback
	if controls:
		var value = controls.get(property_name)
		if value is Array:
			params = value
	input_mapper.apply_configs(params, fallback)
