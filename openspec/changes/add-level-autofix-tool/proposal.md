## Why
Level designers rely on the validator warnings to catch blocking issues (impassable goals, starts that overlap or sit off the map), but those warnings still leave the level unplayable until someone manually edits the offending rows. When multiple rows are wrong the iteration loop stalls because QA cannot even boot the map to gather context. We need the tooling to offer deterministic repairs or at least ready-to-apply patches so designers can keep iterating even when data is messy.

## What Changes
- Extend the level row validator with auto-repair hooks that detect the known blocking states (impassable goal tiles, impassable player/neutral starts, starts off the map, starts overlapping an existing unit/goal).
- Introduce a LevelAutoFixService that can suggest alternate coordinates and apply them to a mutable level copy so gameplay can proceed. Repairs must be deterministic, logged, and tied to the offending row resource for traceability.
- Surface suggested repairs to designers through a structured report (JSON + console summary) so they can update the ResourceTables rows once they accept the fix.
- Expose a flag on the level builder/validator pipeline so QA or CI can opt into auto-fixing (enabled for ad-hoc/dev builds, disabled for shipping builds).

## Impact
- Designers and QA can load levels with bad data and immediately see how the engine would repair them instead of editing rows blind.
- Gameplay no longer hard-fails when a spawn goal is impassable; instead it applies the deterministic fix and emits a warning so the test session can continue.
- Requires new repair algorithms, reporting, and toggles around level loading—these must be covered by tests to avoid silently masking issues in production.
