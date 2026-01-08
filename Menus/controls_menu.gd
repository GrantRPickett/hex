extends Control

signal back_requested

@onready var _layouts_label: RichTextLabel = $Panel/VBox/Layouts

func _ready() -> void:
    _refresh_layouts()

func _refresh_layouts() -> void:
    var cs = ControlSettings
    var lines := []
    lines.append("Move actions: %s" % [str(cs.move_actions)])
    lines.append("Camera actions: %s" % [str(cs.camera_actions)])
    lines.append("Selection actions: %s" % [str(cs.selection_actions)])
    lines.append("Pause actions: %s" % [str(cs.pause_actions)])
    _layouts_label.text = "\n".join(lines)

func reset_and_apply_defaults() -> void:
    ControlSettings.reset_inputs_to_defaults()
    # Reapply input maps so changes take effect
    InputMapper.apply_configs(ControlSettings.move_actions)
    InputMapper.apply_configs(ControlSettings.camera_actions)
    InputMapper.apply_configs(ControlSettings.selection_actions)
    InputMapper.apply_configs(ControlSettings.pause_actions)
    _refresh_layouts()

func _on_back_pressed() -> void:
    back_requested.emit()

func _on_reset_pressed() -> void:
    reset_and_apply_defaults()

