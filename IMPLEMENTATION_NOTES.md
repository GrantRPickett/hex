# Stuck Unit Detection & Action UI Implementation

## Summary
Added functionality to detect when units are completely stuck (no valid moves or actions) and created a UI system for selecting unit actions.

## Changes

### 1. **New File: `Gameplay/unit_action_manager.gd`**
   - **`is_unit_stuck(unit, terrain_map, unit_manager) -> bool`**
	 - Returns `true` if unit cannot move to any unoccupied space AND cannot perform any actions
	 - Checks if unit is dead (stuck by default)
	 - Checks if any movement spaces are reachable and unoccupied
	 - Checks if any actions are available (attack, aid, work on goal, loot)
	 - Considers adjacent enemies for combat and adjacent injured allies for aiding

   - **`get_available_actions(unit, terrain_map, unit_manager) -> Array[Dictionary]`**
	 - Returns list of available actions for the current unit
	 - Each action contains: `type`, `label`, `available`, and optional `targets`
	 - Possible actions: `move`, `attack`, `aid`, `work_on_goal`, `loot`, `wait`

### 2. **Updated: `GUI/info.gd`**
   - Added action UI system with buttons for available actions
   - New fields:
	 - `actions_panel`: Panel holding action buttons
	 - `actions_container`: VBoxContainer for organizing buttons
	 - `unit_stuck_label`: Label showing if unit is stuck
   - New methods:
	 - `update_available_actions(unit, terrain_map, unit_manager)`: Populates action buttons
	 - `_on_action_button_pressed(action)`: Handles action execution from UI
   - Actions execute directly:
	 - **Attack**: Targets adjacent enemy
	 - **Aid**: Restores 1 willpower to injured ally
	 - **Work on Goal**: Applies progress to goal unit is standing on
	 - **Loot**: Picks up items at current position
	 - **Wait**: Ends turn (game flow handles)

### 3. **New Signal in Info**
   - `action_executed(action_type: String)`: Emitted when an action is executed from UI

## Usage

### Detecting Stuck Units
```gdscript
var stuck = UnitActionManager.is_unit_stuck(unit, terrain_map, unit_manager)
if stuck:
	print("Unit cannot move or act!")
```

### Getting Available Actions
```gdscript
var actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
for action in actions:
	print(action.label)  # e.g., "Attack (1 enemies)", "Move (5 spaces)"
```

### Updating UI
```gdscript
info.update_available_actions(unit, terrain_map, unit_manager)
```

## Testing
- Basic tests verify manager methods exist and functionality
- Dead units correctly identified as stuck
- Unit stuck detection considers adjacent units for possible actions

## Integration Points
- Call from `TurnController` when player unit's turn starts
- Call from `HUDController` to update UI
- Connect to `Info.action_executed` signal if custom behavior needed for action execution
