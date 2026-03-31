#class_name InputModeManager
extends Node

## InputModeManager
## Manages global input contexts to ensure correct mapping and focus management.

signal mode_changed(new_mode: String)

var current_mode: GameConstants.InputModes = GameConstants.InputModes.MENU: set = set_mode

func set_mode(new_mode: GameConstants.InputModes) -> void:
	if current_mode == new_mode:
		return
	var old_mode := current_mode
	current_mode = new_mode
	mode_changed.emit(new_mode)
	GameLogger.info(GameLogger.Category.INPUT, "Input Mode changed: %s -> %s" % [old_mode, new_mode])

func is_menu_mode() -> bool:
	return current_mode == GameConstants.InputModes.MENU or current_mode == GameConstants.InputModes.INVENTORY
