# Change: Implement Small Backlog Items

## Why
Implement high-value, small-scope (S/XS) items from the backlog to improve UX, aesthetics, and technical consistency.

## What Changes
- **HUD UX**: Auto-collapse lists > 3 in HUD panels to reduce clutter.
- **Data**: Expose `starting_weather` in Level JSON for earlier scenario setups.
- **Aesthetics**:
    - **UI Theming**: Refine panel color styles for better consistency.
    - **Map Visuals**: Introduce more descriptive location sprites (moving beyond just "rocks").

## Impact
- **Affected specs**: `hud-actions`, `level-data` (new), `ui-theming` (new), `map-visuals` (new).
- **Affected code**: `HUD` components, `json_to_tres.py`, `LevelRowLoader.gd`, and art resources.
