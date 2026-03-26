#class_name AccessibilityManager
extends Node

signal high_contrast_changed(enabled: bool)
signal reduced_motion_changed(enabled: bool)
signal ui_scale_changed(value: float)

func _ready() -> void:
	if GameConfig:
		GameConfig.config_changed.connect(_on_config_changed)
	
	# Initial application
	_apply_ui_scale(get_ui_scale())

func is_high_contrast_enabled() -> bool:
	return bool(GameConfig.get_value(GameConfig.Paths.ACCESSIBILITY_HIGH_CONTRAST, false))

func is_reduced_motion_enabled() -> bool:
	return bool(GameConfig.get_value(GameConfig.Paths.ACCESSIBILITY_REDUCED_MOTION, false))

func get_ui_scale() -> float:
	return float(GameConfig.get_value(GameConfig.Paths.ACCESSIBILITY_UI_SCALE, 1.0))

func _on_config_changed(path: String, value: Variant) -> void:
	match path:
		GameConfig.Paths.ACCESSIBILITY_HIGH_CONTRAST:
			high_contrast_changed.emit(bool(value))
		GameConfig.Paths.ACCESSIBILITY_REDUCED_MOTION:
			reduced_motion_changed.emit(bool(value))
		GameConfig.Paths.ACCESSIBILITY_UI_SCALE:
			var val := float(value)
			ui_scale_changed.emit(val)
			_apply_ui_scale(val)

func _apply_ui_scale(value: float) -> void:
	if is_inside_tree():
		get_tree().root.content_scale_factor = value
