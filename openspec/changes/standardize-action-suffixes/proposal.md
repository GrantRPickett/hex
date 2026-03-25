# Change: Standardize Action Suffixes

## Why

Action indicators (★, ▲, etc.) are currently inconsistent across different action types (Attack vs. Gather vs. Convince) and can be overly noisy when multiple targets are involved (e.g., `[★, ▲]`). Collapsing to the "best" result and ensuring a consistent format improves UI scannability.

## What Changes

- **Suffix Collapsing**: Group indicators will now only show the single "best" quality symbol (using the priority ★ > ▲ > ◆ > ● > ▼) instead of a list.
- **Label Uniformity**: `GATHER`, `CONVINCE`, and `ATTACK` actions will use the same standardized `ActionLabelFormatter` formatting logic.
- **Submenu Precision**: The attribute selection grid will refresh its indicators specifically for the selected target when navigating from a multi-target action.

## Impact

- **Affected specs**: `hud-actions`
- **Affected code**: `CombatSystem.gd`, `ActionLabelFormatter.gd`, `ActionsPanel.gd`
