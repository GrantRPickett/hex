extends Control

signal back_requested

@onready var _layouts_label: RichTextLabel = $CanvasLayer/Panel/VBox/Scroll/Layouts

func _ready() -> void:
	_refresh_layouts()

func _refresh_layouts() -> void:
	var control_settings = get_tree().root.get_node_or_null("ControlSettings")
	if control_settings == null:
		push_error("ControlSettings autoload not found!")
		return

	var lines := []

	var groups = [
		{"name": "Movement", "data": InputActions.MOVEMENT_DEFAULTS},
		{"name": "Interaction", "data": InputActions.INTERACTION_DEFAULTS},
		{"name": "Camera", "data": InputActions.CAMERA_DEFAULTS},
		{"name": "Selection", "data": InputActions.SELECTION_DEFAULTS},
		{"name": "Pause", "data": InputActions.PAUSE_DEFAULTS},
	]

	for group in groups:
		lines.append("[b]%s[/b]" % group.name)
		for entry in group.data:
			var action: String = entry["action"]
			var events = InputMap.action_get_events(action)
			var keys := []
			for event in events:
				keys.append(_get_event_label(event))

			if keys.is_empty():
				keys.append("Unbound")

			lines.append("  %s: %s" % [action.capitalize(), ", ".join(keys)])
		lines.append("")

	_layouts_label.text = "\n".join(lines)

func reset_and_apply_defaults() -> void:
	var control_settings = get_tree().root.get_node_or_null("ControlSettings")
	if control_settings == null:
		push_error("ControlSettings autoload not found!")
		return
	var input_mapper = get_tree().root.get_node_or_null("InputMapper")
	if input_mapper == null:
		push_error("InputMapper autoload not found!")
		return
	control_settings.reset_inputs_to_defaults()
	# Reapply input maps so changes take effect
	input_mapper.apply_configs(control_settings.move_actions)
	input_mapper.apply_configs(control_settings.camera_actions)
	input_mapper.apply_configs(control_settings.selection_actions)
	input_mapper.apply_configs(control_settings.pause_actions)
	_refresh_layouts()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_reset_pressed() -> void:
	reset_and_apply_defaults()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _get_event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var keycode = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		return OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		var btn_name = "Mouse " + str(event.button_index)
		if event.button_index == MOUSE_BUTTON_LEFT: btn_name = "Left Click"
		elif event.button_index == MOUSE_BUTTON_RIGHT: btn_name = "Right Click"
		elif event.button_index == MOUSE_BUTTON_MIDDLE: btn_name = "Middle Click"
		return btn_name
	elif event is InputEventJoypadButton:
		return "JoyBtn " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var sign_str = "+" if event.axis_value > 0 else "-"
		return "JoyAxis " + str(event.axis) + sign_str
	return "Unknown Input"
