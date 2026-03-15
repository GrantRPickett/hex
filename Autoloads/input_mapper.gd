#class_name InputMapper
extends Node

func apply_configs(configs: Array, fallback: Array = []) -> void:
	var list := configs
	if list.is_empty():
		list = fallback
	for config in list:
		var action: String = config.get("action", "")
		if action == "":
			continue
		var keys: = _as_int_array(config.get("keys", []))
		var buttons:  = _as_int_array(config.get("joy_buttons", []))
		var mouse_buttons:  = _as_int_array(config.get("mouse_buttons", []))
		map_action(action, keys, buttons, mouse_buttons)

func map_action(action: String, keys: Array, buttons: Array = [], mouse_buttons: Array = []) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	for key in keys:
		var key_event := InputEventKey.new()
		key_event.keycode = int(key) as Key
		InputMap.action_add_event(action, key_event)
	for button in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = int(button) as JoyButton
		InputMap.action_add_event(action, button_event)
	for mouse_button in mouse_buttons:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = int(mouse_button) as MouseButton
		InputMap.action_add_event(action, mouse_event)

func clear_action(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)

func _as_int_array(value) -> Array:
	if value is PackedInt32Array:
		return value.to_array()
	if value is Array:
		return value.duplicate()
	return []
