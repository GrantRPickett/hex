# Design: Input Mode Manager & Controller UX

## Context
The game currently treats all input as global, regardless of whether the user is in a menu, on the map, or interacting with a unit. This leads to conflicting inputs when using a controller (e.g., D-pad moving the map while in a menu).

## Goals
- **Contextual Input**: Filter and route inputs based on the active "Mode".
- **Controller Parity**: Ensure every menu and gameplay state is fully navigable with a controller.
- **De-confliction**: Prevent map movement while menus are open.

## Decisions

### 1. InputModeManager (Autoload)
A new singleton to track the global input state.

```gdscript
enum Mode {
	MENU,          # Settings, Main Menu, Pause
	MAP_FREE_CAM,  # Exploring the grid (no unit selected)
	UNIT_ACTION,   # Unit selected, targeting or moving
	DIALOGUE,      # Conversing with NPC
	INVENTORY      # Managing items
}

var current_mode: Mode = Mode.MENU
```

### 2. Focus Neighbors (UI)
In all `VBoxContainer` and `HBoxContainer` based menus, we will:
- Set `focus_mode = FOCUS_ALL` for interactive elements.
- Use `focus_neighbor_*` if automatic focus is insufficient (e.g., hopping between columns).
- Add a "Focus Handler" to `SettingsMenu` to set initial focus when a tab changes.

### 3. Command Routing
The `InputCommandRouter` will query `InputModeManager` to determine if a command is valid for the current mode.

```gdscript
# Example logic in InputController or Router
func _unhandled_input(event: InputEvent) -> void:
    if InputModeManager.current_mode == InputModeManager.Mode.MENU:
        return # Let GUI handle focus-based input
    # Process gameplay commands...
```

## Risks / Trade-offs
- **Mode Desync**: We must ensure `session_ended` or `menu_closed` always restores the correct mode.
- **Complexity**: Implementing this for EVERY UI element takes time, so we'll start with the Settings Menu.
