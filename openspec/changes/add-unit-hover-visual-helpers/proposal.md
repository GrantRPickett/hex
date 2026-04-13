# Change: Add Unit Hover Visual Helpers

## Why
To enhance the visual feedback and game feel, we need a way to clearly indicate which unit is active and which unit is being targeted when hovering action buttons. Squash and stretch (S&S) provides a dynamic "alive" feel to the active unit, while temporary wiggle and grid highlights provide clear target confirmation.

## What Changes
- **Added** continuous Squash and Stretch cycle for the active unit.
- **Added** temporary Wiggle animation for units when their corresponding action buttons are hovered.
- **Added** hex grid visual highlight for units when their corresponding action buttons are hovered.
- **Added** robust reset logic to all unit visual helpers to prevent lingering distortions (non-neutral scale or rotation).

## Impact
- **Unit**: New methods/logic for S&S and Wiggle animations.
- **UnitManager**: Trigger S&S on selection change.
- **ActionsPanel**: Emit hover signals from action, target, and attribute buttons.
- **GridVisuals**: New overlay for action target highlight.
- **HUDController / HoverService**: Coordinate between UI hover and Unit/Grid visuals.
