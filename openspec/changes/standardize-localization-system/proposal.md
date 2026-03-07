# Change: Standardize Localization System

## Why
The current localization system relies on a hardcoded dictionary in `localization_strings.gd`, which is difficult to maintain, doesn't integrate with Godot's native translation features, and doesn't support automatic Line ID generation for Dialogue Manager.

## What Changes
- **Translation Format**: Transition from `localization_strings.gd` to Godot's native CSV translation format.
- **Dialogue Generator**: Update `json_to_tres.py` to auto-inject stable Line IDs into generated `.dialogue` files.
- **Workflow**: Create a tool to sync current strings to CSV and ensure new dialogue lines are automatically trackable.
- **Integration**: Update `DialogueActionService` and `SettingsMenu` to use Godot's `tr()` instead of custom lookup.

## Impact
- Affected specs: `localization` (new)
- Affected code: `json_to_tres.py`, `localization_strings.gd`, `DialogueActionService.gd`, `settings_menu.gd`, `HUD` components.
