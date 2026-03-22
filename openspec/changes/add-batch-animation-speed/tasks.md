# Implementation Tasks - Batch Animation Speed

- [x] **Preparation**
    - [x] Update `GameConstants` with `BATCH_ANIMATIONS_ENABLED`.
    - [x] Update `GameConfig` defaults and paths.
    - [x] Update `SettingsMenu` UI to include the "Batch" toggle row.
- [x] **Core Implementation**
    - [x] Create `BatchAnimationBuffer` helper class.
    - [x] Update `AnimationRequestService` to support buffering.
    - [x] Implement `flush_batch()` in `AnimationRequestService`.
- [x] **Integration & Polish**
    - [x] Update `TurnController` to manage batching state.
    - [x] Trigger `flush_batch()` at end of round in `TurnController`.
    - [x] Verify sprite flipping and UI feedback handling in batch mode.
- [x] **Verification**
    - [x] Write unit tests for `BatchAnimationBuffer`.
    - [x] Write integration tests for batching logic.
    - [x] Manually verify in Godot (simulated via tests).
