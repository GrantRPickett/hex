# Change: Redesign Action Menu Layout

## Why

The current vertical stack of buttons in the action menu and submenus is starting to overlap the hexagonal grid, especially when multiple targets or attributes are available. Improving the layout to a grid for attributes and refining target selection will enhance visibility and usability.

## What Changes

- **Action Menu**: Refine the top-level action list to ensure it doesn't overlap the grid.
- **Attribute Selection**: Change from a vertical list to a 3x2 grid with paired stats (Grit/Flow, Gusto/Focus, Shine/Shade).
- **Target Selection**: Improve the navigation and display for opposed vs. unopposed checks when multiple targets are near or nearby.

## Impact

- Affected specs: `hud-actions`
- Affected code: `GUI/actions_panel.gd`, `GUI/HUD/hud_component_factory.gd`
