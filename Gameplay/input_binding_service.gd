class_name InputBindingService
extends RefCounted

const InputActions := preload("res://Resources/input_actions.gd")

func apply_bindings(control_settings: Node, input_mapper: Node) -> void:
	if input_mapper == null:
		return
	input_mapper.apply_configs(_movement_actions(control_settings), InputActions.MOVEMENT_DEFAULTS)
	input_mapper.apply_configs(_interaction_actions(control_settings), InputActions.INTERACTION_DEFAULTS)
	input_mapper.apply_configs(_camera_actions(control_settings), InputActions.CAMERA_DEFAULTS)
	input_mapper.apply_configs(_selection_actions(control_settings), InputActions.SELECTION_DEFAULTS)
	input_mapper.apply_configs(_pause_actions(control_settings), InputActions.PAUSE_DEFAULTS)

func _movement_actions(control_settings: Node) -> Array:
	if control_settings and not control_settings.move_actions.is_empty():
		return control_settings.move_actions
	return []

func _interaction_actions(control_settings: Node) -> Array:
	if control_settings and not control_settings.interaction_actions.is_empty():
		return control_settings.interaction_actions
	return []

func _camera_actions(control_settings: Node) -> Array:
	if control_settings and not control_settings.camera_actions.is_empty():
		return control_settings.camera_actions
	return []

func _selection_actions(control_settings: Node) -> Array:
	if control_settings and not control_settings.selection_actions.is_empty():
		return control_settings.selection_actions
	return []

func _pause_actions(control_settings: Node) -> Array:
	if control_settings and not control_settings.pause_actions.is_empty():
		return control_settings.pause_actions
	return []
