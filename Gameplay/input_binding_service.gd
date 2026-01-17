class_name InputBindingService
extends RefCounted

const InputActions := preload("res://Resources/input_actions.gd")

func apply_bindings(control_settings, input_mapper) -> void:
	if input_mapper == null:
		push_warning("InputBindingService: input_mapper is null. Bindings not applied.")
		return
	input_mapper.apply_configs(_movement_actions(control_settings), InputActions.MOVEMENT_DEFAULTS)
	input_mapper.apply_configs(_interaction_actions(control_settings), InputActions.INTERACTION_DEFAULTS)
	input_mapper.apply_configs(_camera_actions(control_settings), InputActions.CAMERA_DEFAULTS)
	input_mapper.apply_configs(_selection_actions(control_settings), InputActions.SELECTION_DEFAULTS)
	input_mapper.apply_configs(_pause_actions(control_settings), InputActions.PAUSE_DEFAULTS)

func _movement_actions(control_settings) -> Array:
	if control_settings:
		var actions = control_settings.get("move_actions")
		if actions and not actions.is_empty():
			return actions
	return []

func _interaction_actions(control_settings) -> Array:
	if control_settings:
		var actions = control_settings.get("interaction_actions")
		if actions and not actions.is_empty():
			return actions
	return []

func _camera_actions(control_settings) -> Array:
	if control_settings:
		var actions = control_settings.get("camera_actions")
		if actions and not actions.is_empty():
			return actions
	return []

func _selection_actions(control_settings) -> Array:
	if control_settings:
		var actions = control_settings.get("selection_actions")
		if actions and not actions.is_empty():
			return actions
	return []

func _pause_actions(control_settings) -> Array:
	if control_settings:
		var actions = control_settings.get("pause_actions")
		if actions and not actions.is_empty():
			return actions
	return []
