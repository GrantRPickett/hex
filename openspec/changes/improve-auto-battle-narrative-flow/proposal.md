# Change: Improve Auto-Battle Narrative Flow

## Why
Using auto-battle (auto-act) mode during narrative sequences currently causes the game to get stuck in narrative mode, especially when pausing/unpausing. Dialogue popups block input and disrupt the automated flow.

## What Changes
- **MODIFIED**: `GameCommandContext` to include an `auto_battle_active` flag.
- **MODIFIED**: `TriggerDialogueCommand` and `HUDController` to skip dialogue balloons ONLY when `auto_battle_active` is true.
- **NEW**: `InteractionLogPanel` UI component to capture and display ALL narrative lines and combat barks, regardless of system mode.
- **NEW**: Logic in `HUDController` and `TriggerDialogueCommand` to append narrative text to the `InteractionLogPanel` for every triggered interaction.

## Impact
- Affected specs: `narrative` (NEW), `auto-battle` (NEW)
- Affected code: `trigger_dialogue_command.gd`, `hud_controller.gd`, `actions_panel.gd`, `game_command_context.gd`
