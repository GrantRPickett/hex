extends Control

signal back_requested

@onready var _layouts_label: RichTextLabel = $Panel/VBox/Layouts

func _ready() -> void:
	_refresh_layouts()

func _refresh_layouts() -> void:
	var control_settings = get_tree().root.get_node_or_null("ControlSettings")
	if control_settings == null:
		push_error("ControlSettings autoload not found!")
		return
	var lines := []
	lines.append("Move actions: %s" % [str(control_settings.move_actions)])
	lines.append("Camera actions: %s" % [str(control_settings.camera_actions)])
	lines.append("Selection actions: %s" % [str(control_settings.selection_actions)])
	lines.append("Pause actions: %s" % [str(control_settings.pause_actions)])
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

