## Context
The HEX project currently handles animations sequentially as they are requested. In "auto act" mode, this leads to a "one-by-one" movement pattern. The user wants a way to batch these animations so they all fire at once at the end of a round.

## Goals / Non-Goals
- **Goals**:
  - Provide a "Batch" animation speed setting.
  - Buffer unit tweens (move and action) during auto-act.
  - Trigger all buffered tweens simultaneously at the end of the round.
  - Ensure game state updates are NOT deferred.
- **Non-Goals**:
  - Changing the core turn logic or AI decision-making.
  - Batching non-gameplay animations (HUD warnings, etc.) unless specifically needed.

## Decisions
- **BatchAnimationBuffer**: A new class will be created to store animation requests. It will hold a list of callable or data structures representing the tweens to be created.
- **AnimationRequestService Integration**: The service will check the current speed setting. If it's `BATCH`, it will redirect gameplay requests to the buffer.
- **TurnController Hook**: The `_start_new_round` method in `TurnController` is the ideal place to flush the buffer, as it's called when the turn queue for the current round is exhausted.
- **Parallel Tweens**: Using Godot's `create_tween()` multiple times on different objects naturally runs them in parallel unless chained to a single object or sequenced.

## Risks / Trade-offs
- **Overlapping Animations**: If many units move to the same spot or cross paths, it might look messy. This is acceptable for an "autobattler" feel.
- **Signal Completion**: We need to ensure that `animation_completed` signals are still fired correctly in batch mode.

## Migration Plan
- Add the new constant to `GameConstants`.
- Update `GameConfig` and `SettingsMenu`.
- Implement and integrate the buffer.

## Open Questions
- Should the game *wait* for the batched animations to finish before starting the next round? (Assumption: Yes, to avoid visual desync if the next round starts immediately).
