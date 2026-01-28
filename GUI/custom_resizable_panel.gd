class_name CustomResizablePanel
extends PanelContainer

## A generic resizable panel that automatically adjusts its size based on its content.
## It provides padding and can enforce a minimum size.

@export var padding_left: int = 8:
	set(value):
		padding_left = value
		_update_padding()
@export var padding_top: int = 8:
	set(value):
		padding_top = value
		_update_padding()
@export var padding_right: int = 8:
	set(value):
		padding_right = value
		_update_padding()
@export var padding_bottom: int = 8:
	set(value):
		padding_bottom = value
		_update_padding()

@export var min_width: int = 0:
	set(value):
		min_width = value
		_update_min_size()
@export var min_height: int = 0:
	set(value):
		min_height = value
		_update_min_size()

func _ready() -> void:
	# Default to shrinking to content
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_update_padding()
	_update_min_size()

func _update_padding() -> void:
	add_theme_constant_override("panel_padding_left", padding_left)
	add_theme_constant_override("panel_padding_top", padding_top)
	add_theme_constant_override("panel_padding_right", padding_right)
	add_theme_constant_override("panel_padding_bottom", padding_bottom)

func _update_min_size() -> void:
	custom_minimum_size = Vector2(min_width, min_height)

func force_fit_content() -> void:
	# Resets size to minimum allowed by content
	size = Vector2.ZERO
	custom_minimum_size = Vector2(min_width, min_height)
