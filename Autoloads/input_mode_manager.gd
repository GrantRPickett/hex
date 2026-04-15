#class_name InputModeManager
extends Node

## InputModeManager
## Manages global input contexts to ensure correct mapping and focus management.

const GUINavigationHelper := preload("res://scripts/ui_navigation_helper.gd")

signal mode_changed(new_mode: String)

var current_mode: GameConstants.InputModes = GameConstants.InputModes.MENU: set = set_mode

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		GameLogger.info(GameLogger.Category.INPUT, "Joypad BUTTON event received: %s" % event.as_text())
		if is_menu_mode() and get_viewport().gui_get_focus_owner() == null:
			_ensure_menu_focus()
	elif event is InputEventJoypadMotion:
		# Log axes occasionally or if necessary, but keep button logs constant
		# GameLogger.info(GameLogger.Category.INPUT, "Joypad AXIS event received: %s" % event.as_text())
		if is_menu_mode() and get_viewport().gui_get_focus_owner() == null:
			_ensure_menu_focus()

func set_mode(new_mode: GameConstants.InputModes) -> void:
	if current_mode == new_mode:
		return
	var old_mode := current_mode
	current_mode = new_mode
	mode_changed.emit(new_mode)
	GameLogger.info(GameLogger.Category.INPUT, "Input Mode changed: %s -> %s" % [old_mode, new_mode])
	
	if is_menu_mode():
		_ensure_menu_focus()

func is_menu_mode() -> bool:
	return current_mode == GameConstants.InputModes.MENU or current_mode == GameConstants.InputModes.INVENTORY

func _ensure_menu_focus() -> void:
	var viewport := get_viewport()
	if viewport.gui_get_focus_owner() != null:
		return
	
	# Try to find a focusable element in the current tree
	# We prioritize nodes under CanvasLayers or specific menu roots
	var focusable = _find_best_focusable(get_tree().root)
	if focusable:
		focusable.grab_focus()

func _find_best_focusable(node: Node) -> Control:
	# Avoid searching deep into the entire scene tree if possible
	# Look for active menus first
	var potential_roots = []
	
	# Common menu names/types
	for child in node.get_children():
		if child is CanvasLayer and child.visible:
			potential_roots.append(child)
		elif child is Control and child.visible:
			potential_roots.append(child)
	
	for root in potential_roots:
		var found = GUINavigationHelper.find_first_focusable(root)
		if found:
			return found
	
	return null
