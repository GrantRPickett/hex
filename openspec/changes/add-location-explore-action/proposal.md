# Change: Add Location Explore Action

## Why

Currently, locations only support "interact" tasks. Players need to be able to "explore" locations specifically using a skill-based opposed check to uncover information or progress the narrative.

## What Changes

- Add support for "explore" tasks in the `TaskActionProvider`.
- Expose an "Explore" button in the Action Panel when a unit is on a hex with an active explore task.
- Ensure the "Explore" action triggers an opposed check based on the task's requirements.

## Impact

- Affected specs: `location-interaction`
- Affected code: `TaskActionProvider.gd`, `Task.gd`, `UnitActionManager.gd`
