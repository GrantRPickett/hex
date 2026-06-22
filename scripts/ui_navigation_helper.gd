class_name GUINavigationHelper
extends Object

## Utility for managing UI navigation and focus styling.

static func apply_focus_style(control: Control) -> void:
	if not is_instance_valid(control):
		return
	
	# Focus style (Solid Cyan Border)
	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = Color(0, 0, 0, 0)
	focus_sb.draw_center = false
	focus_sb.border_width_left = 2
	focus_sb.border_width_top = 2
	focus_sb.border_width_right = 2
	focus_sb.border_width_bottom = 2
	focus_sb.border_color = GameColors.INV_HIGHLIGHT
	focus_sb.set_corner_radius_all(2)
	focus_sb.expand_margin_left = 2
	focus_sb.expand_margin_top = 2
	focus_sb.expand_margin_right = 2
	focus_sb.expand_margin_bottom = 2
	
	control.add_theme_stylebox_override("focus", focus_sb)
	
	# Hover style (Semi-transparent Cyan Border)
	# This ensures mouse users get the same visual convention
	var hover_sb := focus_sb.duplicate()
	hover_sb.border_color = GameColors.INV_HIGHLIGHT
	hover_sb.border_color.a = 0.5
	
	if control is Button:
		control.add_theme_stylebox_override("hover", hover_sb)
		if control.focus_mode == Control.FOCUS_NONE:
			control.focus_mode = Control.FOCUS_ALL
	elif control is ItemList:
		# ItemList uses 'selected' and 'hovered' styleboxes
		control.add_theme_stylebox_override("cursor", focus_sb)
		control.add_theme_stylebox_override("selected_focus", focus_sb)

static func find_first_focusable(node: Node) -> Control:
	if not node:
		return null
	
	if node is Control and node.visible:
		if node.focus_mode != Control.FOCUS_NONE:
			if not node is Container and not node is Label and not node is ScrollContainer:
				return node
	
	for child in node.get_children():
		var found = find_first_focusable(child)
		if found:
			return found
	return null
