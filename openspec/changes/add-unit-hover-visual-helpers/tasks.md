## 1. Unit Animation Logic
- [ ] 1.1 Add `VisualHelperComponent` logic to `Unit.gd` (or a dedicated component) for Squash & Stretch and Wiggle.
- [ ] 1.2 Implement `start_squash_stretch()` and `stop_squash_stretch()` using Tweens.
- [ ] 1.3 Implement `trigger_wiggle()` and `stop_wiggle()`.
- [ ] 1.4 Ensure reset logic always returns `scale` to `Vector2.ONE` and `rotation` to `0.0`.

## 2. Selection Integration
- [ ] 2.1 Update `UnitManager.gd` to toggle S&S on `selection_changed`.
- [ ] 2.2 Ensure current selected unit starts S&S on ready.

## 3. UI Hover Integration
- [ ] 3.1 Update `ActionsPanel.gd` to emit target unit on button hover (action buttons, target selectors, attribute grid).
- [ ] 3.2 Update `GridVisuals.gd` to support a temporary "action target" highlight.
- [ ] 3.3 Connect `ActionsPanel` hover signals to Unit wiggle and Grid highlight (likely in `HUDController.gd` or a service).

## 4. Verification
- [ ] 4.1 Create test `tests/test_unit_visual_helpers.gd` to verify animation start/stop and reset logic.
- [ ] 4.2 Manually verify hover behavior and S&S cycle resets.
