# Change: Add Batch Animation Speed Setting

## Why
In "auto act" or "auto battle" mode, sequential animations for each unit move and action can feel slow and disconnected. A "Batch" animation setting allows all unit actions in a round to be calculated invisibly and then animated simultaneously at the end of the round, providing a more dynamic and "autobattler-like" visual experience without altering the core turn-based logic.

## What Changes
- **MODIFIED** `GameConstants.Settings`: Added `ANIMATION_SPEED_BATCH` constant.
- **MODIFIED** `GameConfig`: Added "Batch" to the default configuration and speed paths.
- **MODIFIED** `SettingsMenu`: Added "Batch" option to the animation speed dropdown and modernized the UI layout if needed.
- **NEW** `BatchAnimationBuffer`: A helper class to collect and manage delayed animation requests.
- **MODIFIED** `AnimationRequestService`: Implemented buffering logic when "Batch" speed is active.
- **MODIFIED** `TurnController`: Added logic to trigger the batch animation buffer at the end of a round.
- **MODIFIED** `AutoBattleService`: Integrated with the batch buffer to ensure smooth transitions between rounds.

## Impact
- **Affected specs**: `gameplay-settings` (New)
- **Affected code**: `AnimationRequestService.gd`, `TurnController.gd`, `SettingsMenu.gd`, `GameConstants.gd`, `GameConfig.gd`.
- **Performance**: Batching animations may cause a brief visual surge of many tweens, but simplifies the sequential overhead.
