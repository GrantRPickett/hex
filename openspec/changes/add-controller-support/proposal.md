# Change: Add Controller Support and Input Mode Manager

## Why
The current input system lacks robust controller support, especially for UI navigation and context-aware gameplay. Users cannot navigate the settings menu with a controller, and the game lacks a way to switch between different input "modes" (e.g., Map Cursor vs. Menu Navigation).

## What Changes
- **Input Mode Manager**: A new service to handle switching between `MENU`, `MAP`, `UNIT`, and `INVENTORY` input states.
- **Enhanced Controller Mapping**: Complete the `InputActions` defaults with comprehensive joypad bindings for all actions.
- **UI Focus Management**: Update `SettingsMenu` and other core UI scenes to support controller/keyboard navigation via explicit focus links and visual states.
- **BBCode Support**: Enable BBCode on the Controls tab layout display (DONE).

## Impact
- **Affected Specs**: `gameplay-settings` (modified), new `input-system` spec.
- **Affected Code**: `control_settings.gd`, `input_mapper.gd`, `settings_menu.gd`, and various UI scenes.
- **Breaking Changes**: None expected, but input handling logic will be more centralized.
